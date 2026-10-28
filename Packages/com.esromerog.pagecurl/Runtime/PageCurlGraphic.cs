using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace PageCurl
{
    /// <summary>
    /// Draws the page being turned: the flat part, the curl, the folded-over flap and their soft shadows.
    /// <see cref="PageCurlBook"/> drives it every frame. Canvases draw without a depth buffer, so triangles are
    /// emitted back to front: the page is sliced into strips parallel to the curl axis and emitted in the order
    /// they roll up, which is also the order they rise off the page.
    /// </summary>
    [AddComponentMenu("")]
    [RequireComponent(typeof(CanvasRenderer))]
    public sealed class PageCurlGraphic : MaskableGraphic
    {
        internal struct Settings
        {
            public PageFrame Frame;
            public CurlState Curl;
            /// <summary>The whole book rect in page space; shadows are clipped to it.</summary>
            public Rect Bounds;
            public float BaseRadius;
            public int CurlSegments;
            public int TaperSegments;
            public float LiftScale;
            public float ShadowWidth;
            public Vector2 ShadowOffset;
            /// <summary>Light direction in book space, z towards the viewer.</summary>
            public Vector3 LightDirection;
            public float Ambient;
            public float Highlight;
            public float HighlightPower;
        }

        const int ShadowRows = 4;
        const int JoinSegments = 4;

        Texture _front;
        Texture _back;
        Settings _settings;
        bool _hasCurl;

        // Values cached for one mesh rebuild.
        Rect _frontRect;
        Rect _backRect;
        Color32 _vertexColor;
        float _axisU;
        float _axisV;
        Vector3 _light;
        Vector3 _halfVector;
        float _flatDiffuse;
        float _flatHighlight;

        readonly List<float> _uEdges = new();
        readonly List<float> _vEdges = new();
        readonly List<Vector3> _band = new();
        readonly List<Vector3> _cell = new();
        readonly List<Vector3> _scratch = new();
        readonly List<Vector3> _flap = new();
        readonly List<bool> _flapOnFold = new();

        public override Texture mainTexture => _front != null ? _front : s_WhiteTexture;

        internal void SetTextures(Texture front, Texture back)
        {
            _front = front;
            _back = back;
            SetMaterialDirty();
        }

        internal void SetCurl(in Settings settings)
        {
            _settings = settings;
            _hasCurl = true;
            SetVerticesDirty();
        }

        protected override void UpdateMaterial()
        {
            base.UpdateMaterial();
            // The back of the page rides on the per-renderer alpha texture slot, so the shared material never
            // needs per-page copies and stencil masks keep working.
            if (IsActive())
                canvasRenderer.SetAlphaTexture(_back != null ? _back : s_WhiteTexture);
        }

        protected override void OnPopulateMesh(VertexHelper vh)
        {
            vh.Clear();
            if (!_hasCurl)
                return;

            var frame = _settings.Frame;
            var curl = _settings.Curl;
            if (frame.Width <= 0f || frame.Height <= 0f)
                return;

            _frontRect = frame.PageRectInBook;
            _backRect = frame.MirrorRectInBook;
            _vertexColor = color;
            _axisU = Vector2.Dot(curl.Axis, curl.Normal);
            _axisV = Vector2.Dot(curl.Axis, curl.Tangent);
            PrepareLighting();

            // Extent of the page across (u) and along (v) the curl axis.
            float uMin = float.MaxValue, uMax = float.MinValue, vMin = float.MaxValue, vMax = float.MinValue;
            for (int i = 0; i < 4; i++)
            {
                var corner = PageCorner(i);
                float u = Vector2.Dot(corner, curl.Normal) - _axisU;
                float v = Vector2.Dot(corner, curl.Tangent) - _axisV;
                uMin = Mathf.Min(uMin, u);
                uMax = Mathf.Max(uMax, u);
                vMin = Mathf.Min(vMin, v);
                vMax = Mathf.Max(vMax, v);
            }

            float grabV = Vector2.Dot(curl.Grab, curl.Tangent) - _axisV;
            float widestRadius = 0f;
            for (int i = 0; i < 4; i++)
                widestRadius = Mathf.Max(widestRadius, CurlGeometry.RadiusAt(curl, PageCorner(i)));
            BuildEdges(uMin, uMax, vMin, vMax, widestRadius);

            EmitCurlShadow(vh, grabV);
            EmitPage(vh, flat: true);
            EmitFlapShadow(vh, uMax, grabV);
            EmitPage(vh, flat: false);
        }

        void BuildEdges(float uMin, float uMax, float vMin, float vMax, float widestRadius)
        {
            _uEdges.Clear();
            _uEdges.Add(uMin);
            if (uMin < 0f && uMax > 0f)
                _uEdges.Add(0f);
            if (widestRadius > 1e-4f)
            {
                float curlEnd = Mathf.PI * widestRadius;
                int segments = Mathf.Max(1, _settings.CurlSegments);
                for (int k = 1; k <= segments; k++)
                {
                    float u = curlEnd * k / segments;
                    if (u > uMin && u < uMax)
                        _uEdges.Add(u);
                }
            }
            _uEdges.Add(uMax);

            // Only a cone varies along the axis and needs slicing that way.
            var curl = _settings.Curl;
            int slices = curl.Taper != 0f && curl.Radius > 0f ? Mathf.Max(1, _settings.TaperSegments) : 1;
            _vEdges.Clear();
            for (int k = 0; k <= slices; k++)
                _vEdges.Add(Mathf.Lerp(vMin, vMax, k / (float)slices));
        }

        void EmitPage(VertexHelper vh, bool flat)
        {
            var curl = _settings.Curl;
            for (int i = 0; i < _uEdges.Count - 1; i++)
            {
                float u0 = _uEdges[i], u1 = _uEdges[i + 1];
                bool bandIsFlat = u1 <= 0f;
                if (bandIsFlat != flat || u1 - u0 < 1e-5f)
                    continue;

                SetPagePolygon(_band);
                PolygonClipper.Clip(_band, _scratch, curl.Normal, u0 + _axisU);
                PolygonClipper.Clip(_band, _scratch, -curl.Normal, -(u1 + _axisU));
                if (_band.Count < 3)
                    continue;

                if (bandIsFlat)
                {
                    EmitPageCell(vh, _band);
                    continue;
                }

                for (int j = 0; j < _vEdges.Count - 1; j++)
                {
                    _cell.Clear();
                    _cell.AddRange(_band);
                    PolygonClipper.Clip(_cell, _scratch, curl.Tangent, _vEdges[j] + _axisV);
                    PolygonClipper.Clip(_cell, _scratch, -curl.Tangent, -(_vEdges[j + 1] + _axisV));
                    EmitPageCell(vh, _cell);
                }
            }
        }

        void EmitPageCell(VertexHelper vh, List<Vector3> polygon)
        {
            int count = polygon.Count;
            if (count < 3)
                return;

            // Decide the visible side once per cell so a triangle never mixes front and back.
            var centroid = Vector2.zero;
            for (int i = 0; i < count; i++)
                centroid += (Vector2)polygon[i];
            centroid /= count;
            bool back = CurlGeometry.Deform(_settings.Curl, centroid).Angle > Mathf.PI * 0.5f;

            int start = vh.currentVertCount;
            for (int i = 0; i < count; i++)
                AddPageVertex(vh, polygon[i], back);
            for (int i = 1; i < count - 1; i++)
                vh.AddTriangle(start, start + i, start + i + 1);
        }

        void AddPageVertex(VertexHelper vh, Vector2 point, bool back)
        {
            var frame = _settings.Frame;
            var deformed = CurlGeometry.Deform(_settings.Curl, point);
            var position = frame.ToBook(deformed.Position);

            var normal = back ? -deformed.FrontNormal : deformed.FrontNormal;
            var planar = frame.DirectionToBook(new Vector2(normal.x, normal.y));
            Shade(new Vector3(planar.x, planar.y, normal.z), out float shade, out float highlight);

            var vertex = UIVertex.simpleVert;
            // Canvas cameras look down +z, so lifting towards the viewer is negative z.
            vertex.position = new Vector3(position.x, position.y, -deformed.Lift * _settings.LiftScale);
            vertex.color = _vertexColor;
            vertex.uv0 = Normalize(frame.ToBook(point), _frontRect);
            // Where this bit of paper ends up once turned, so the back texture reads the right way round.
            vertex.uv1 = Normalize(frame.ToBook(new Vector2(-point.x, point.y)), _backRect);
            vertex.uv2 = new Vector4(shade, highlight, back ? 1f : 0f, 0f);
            vh.AddVert(vertex);
        }

        void EmitCurlShadow(VertexHelper vh, float grabV)
        {
            var curl = _settings.Curl;
            float width = _settings.ShadowWidth;
            float strength = Mathf.Clamp01(curl.Radius / Mathf.Max(_settings.BaseRadius, 1e-4f)) * Mathf.Clamp01(curl.Progress * 20f);
            if (strength <= 0f || width <= 0f)
                return;

            // Cast on the page underneath, starting under the curl and fading out past its edge.
            var pageRect = new Rect(0f, 0f, _settings.Frame.Width, _settings.Frame.Height);
            for (int j = 0; j < _vEdges.Count - 1; j++)
            {
                float v0 = _vEdges[j], v1 = _vEdges[j + 1];
                float r0 = CurlGeometry.RadiusAlong(curl, v0 - grabV);
                float r1 = CurlGeometry.RadiusAlong(curl, v1 - grabV);
                for (int k = 0; k < ShadowRows; k++)
                {
                    float f0 = k / (float)ShadowRows, f1 = (k + 1) / (float)ShadowRows;
                    _cell.Clear();
                    _cell.Add(CurlShadowPoint(v0, r0, f0, strength));
                    _cell.Add(CurlShadowPoint(v1, r1, f0, strength));
                    _cell.Add(CurlShadowPoint(v1, r1, f1, strength));
                    _cell.Add(CurlShadowPoint(v0, r0, f1, strength));
                    PolygonClipper.ClipToRect(_cell, _scratch, pageRect);
                    EmitShadowPolygon(vh, _cell);
                }
            }
        }

        Vector3 CurlShadowPoint(float v, float radius, float fraction, float strength)
        {
            var curl = _settings.Curl;
            float across = Mathf.Lerp(radius * 0.5f, radius + _settings.ShadowWidth, fraction);
            var point = curl.Axis + curl.Normal * across + curl.Tangent * v;
            float falloff = 1f - fraction;
            return new Vector3(point.x, point.y, strength * falloff * falloff);
        }

        void EmitFlapShadow(VertexHelper vh, float uMax, float grabV)
        {
            var curl = _settings.Curl;
            float foldU = Mathf.PI * curl.Radius;
            if (uMax <= foldU + 1e-4f || _settings.ShadowWidth <= 0f)
                return;

            // The flap casts a soft shadow around its outline onto whatever it lies on. It is strongest while the
            // flap is held high and fades as it settles onto the facing page.
            float lift = Mathf.Clamp01(curl.Radius / Mathf.Max(_settings.BaseRadius, 1e-4f));
            float strength = Mathf.Lerp(0.3f, 1f, lift) * Mathf.Clamp01((1f - curl.Progress) * 10f);
            if (strength <= 0f)
                return;
            float width = _settings.ShadowWidth * Mathf.Lerp(0.35f, 1f, lift);
            var offset = _settings.ShadowOffset * lift;

            // The flap is where the paper has rolled past the top of the cone: u >= PI r(v). The cone radius is linear
            // along the axis, so that boundary is a straight line, here written as dot(p, foldNormal) >= foldOffset.
            float slope = foldU * curl.Taper;
            var foldNormal = curl.Normal - curl.Tangent * slope;
            float foldOffset = foldU + _axisU - slope * (_axisV + grabV);

            SetPagePolygon(_flap);
            PolygonClipper.Clip(_flap, _scratch, foldNormal, foldOffset);
            int count = _flap.Count;
            if (count < 3)
                return;

            float foldTolerance = 1e-3f * _settings.Frame.Width * foldNormal.magnitude;
            _flapOnFold.Clear();
            for (int i = 0; i < count; i++)
            {
                var point = (Vector2)_flap[i];
                bool onFold = Vector2.Dot(point, foldNormal) - foldOffset < foldTolerance;
                _flapOnFold.Add(onFold);
                var landed = CurlGeometry.Deform(curl, point).Position + offset;
                // Where the flap meets the curl it rises off the page, so its shadow fades out towards the fold.
                _flap[i] = new Vector3(landed.x, landed.y, onFold ? 0f : strength);
            }

            float winding = PolygonClipper.SignedArea(_flap) >= 0f ? 1f : -1f;
            for (int i = 0; i < count; i++)
            {
                int next = (i + 1) % count;
                int previous = (i + count - 1) % count;
                var a = _flap[i];
                var b = _flap[next];

                // The fold edge joins the curl; it casts nothing.
                var outward = Outward(a, b, winding);
                if (!(_flapOnFold[i] && _flapOnFold[next]))
                {
                    _cell.Clear();
                    _cell.Add(a);
                    _cell.Add(b);
                    _cell.Add(Extrude(b, outward, width));
                    _cell.Add(Extrude(a, outward, width));
                    PolygonClipper.ClipToRect(_cell, _scratch, _settings.Bounds);
                    EmitShadowPolygon(vh, _cell);
                }

                if (a.z <= 0f)
                    continue;

                // Round the corner between the previous edge and this one with a small fan.
                var previousOutward = Outward(_flap[previous], a, winding);
                for (int k = 0; k < JoinSegments; k++)
                {
                    var from = Vector2.Lerp(previousOutward, outward, k / (float)JoinSegments).normalized;
                    var to = Vector2.Lerp(previousOutward, outward, (k + 1) / (float)JoinSegments).normalized;
                    _cell.Clear();
                    _cell.Add(a);
                    _cell.Add(Extrude(a, from, width));
                    _cell.Add(Extrude(a, to, width));
                    PolygonClipper.ClipToRect(_cell, _scratch, _settings.Bounds);
                    EmitShadowPolygon(vh, _cell);
                }
            }
        }

        void EmitShadowPolygon(VertexHelper vh, List<Vector3> polygon)
        {
            int count = polygon.Count;
            if (count < 3)
                return;

            var frame = _settings.Frame;
            int start = vh.currentVertCount;
            for (int i = 0; i < count; i++)
            {
                var position = frame.ToBook(polygon[i]);
                var vertex = UIVertex.simpleVert;
                vertex.position = new Vector3(position.x, position.y, 0f);
                vertex.color = _vertexColor;
                vertex.uv2 = new Vector4(polygon[i].z, 0f, 0f, 1f);
                vh.AddVert(vertex);
            }
            for (int i = 1; i < count - 1; i++)
                vh.AddTriangle(start, start + i, start + i + 1);
        }

        void PrepareLighting()
        {
            _light = _settings.LightDirection.sqrMagnitude > 1e-6f ? _settings.LightDirection.normalized : Vector3.forward;
            // The viewer looks straight at the book along +z in this lighting space.
            _halfVector = (_light + Vector3.forward).normalized;
            _flatDiffuse = Mathf.Max(Diffuse(_light.z), 1e-3f);
            _flatHighlight = Mathf.Pow(Mathf.Max(_halfVector.z, 0f), _settings.HighlightPower);
        }

        float Diffuse(float normalDotLight) => _settings.Ambient + (1f - _settings.Ambient) * Mathf.Max(normalDotLight, 0f);

        /// <summary>Lighting relative to a flat page, so pages at rest keep their exact colours.</summary>
        void Shade(Vector3 normal, out float shade, out float highlight)
        {
            shade = Diffuse(Vector3.Dot(normal, _light)) / _flatDiffuse;
            float specular = Mathf.Pow(Mathf.Max(Vector3.Dot(normal, _halfVector), 0f), _settings.HighlightPower);
            highlight = _settings.Highlight * Mathf.Max(specular - _flatHighlight, 0f);
        }

        Vector2 PageCorner(int index)
        {
            float width = _settings.Frame.Width, height = _settings.Frame.Height;
            return index switch
            {
                0 => Vector2.zero,
                1 => new Vector2(width, 0f),
                2 => new Vector2(width, height),
                _ => new Vector2(0f, height)
            };
        }

        void SetPagePolygon(List<Vector3> polygon)
        {
            polygon.Clear();
            for (int i = 0; i < 4; i++)
                polygon.Add(PageCorner(i));
        }

        static Vector2 Normalize(Vector2 point, Rect rect) =>
            new((point.x - rect.xMin) / Mathf.Max(rect.width, 1e-5f), (point.y - rect.yMin) / Mathf.Max(rect.height, 1e-5f));

        static Vector2 Outward(Vector3 from, Vector3 to, float winding)
        {
            var edge = (Vector2)(to - from);
            if (edge.sqrMagnitude < 1e-10f)
                return Vector2.zero;
            edge.Normalize();
            return new Vector2(edge.y, -edge.x) * winding;
        }

        static Vector3 Extrude(Vector3 point, Vector2 direction, float distance) =>
            new(point.x + direction.x * distance, point.y + direction.y * distance, 0f);
    }
}
