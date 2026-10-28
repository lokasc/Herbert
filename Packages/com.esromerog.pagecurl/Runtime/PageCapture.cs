using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.UI;
using Object = UnityEngine.Object;

namespace PageCurl
{
    /// <summary>
    /// Renders a uGUI hierarchy into a RenderTexture. The content is briefly moved onto a hidden world-space canvas
    /// in front of a hidden orthographic camera, rendered once, and put back, all within one frame.
    /// </summary>
    internal sealed class PageCapture : IDisposable
    {
        // Far away from anything a scene camera would see.
        static readonly Vector3 RigPosition = new(0f, -20000f, 0f);
        const float CameraDistance = 50f;

        readonly GameObject _rig;
        readonly Camera _camera;
        readonly Canvas _canvas;
        readonly RectTransform _canvasRect;

        public PageCapture(int layer)
        {
            _rig = new GameObject("[Page Curl Capture]") { hideFlags = HideFlags.HideAndDontSave, layer = layer };
            _rig.transform.position = RigPosition;

            var cameraObject = new GameObject("Camera") { hideFlags = HideFlags.HideAndDontSave, layer = layer };
            cameraObject.transform.SetParent(_rig.transform, false);
            cameraObject.transform.localPosition = new Vector3(0f, 0f, -CameraDistance);
            _camera = cameraObject.AddComponent<Camera>();
            _camera.enabled = false;
            _camera.orthographic = true;
            _camera.clearFlags = CameraClearFlags.SolidColor;
            _camera.cullingMask = 1 << layer;
            _camera.nearClipPlane = 0.1f;
            _camera.farClipPlane = CameraDistance * 2f;
            _camera.allowHDR = false;
            _camera.allowMSAA = false;
            _camera.useOcclusionCulling = false;

            var canvasObject = new GameObject("Canvas", typeof(RectTransform)) { hideFlags = HideFlags.HideAndDontSave, layer = layer };
            canvasObject.transform.SetParent(_rig.transform, false);
            _canvas = canvasObject.AddComponent<Canvas>();
            _canvas.renderMode = RenderMode.WorldSpace;
            _canvas.worldCamera = _camera;
            _canvas.additionalShaderChannels = AdditionalCanvasShaderChannels.TexCoord1 | AdditionalCanvasShaderChannels.TexCoord2 |
                                               AdditionalCanvasShaderChannels.TexCoord3 | AdditionalCanvasShaderChannels.Normal |
                                               AdditionalCanvasShaderChannels.Tangent;
            _canvasRect = (RectTransform)canvasObject.transform;
            _canvasRect.pivot = new Vector2(0.5f, 0.5f);
        }

        /// <param name="content">Hierarchy to draw; it is stretched to fill <paramref name="size"/>.</param>
        /// <param name="size">Page size in the book's canvas units.</param>
        public void Render(RectTransform content, RenderTexture target, Vector2 size, Color background)
        {
            var parent = content.parent;
            int siblingIndex = content.GetSiblingIndex();
            var anchorMin = content.anchorMin;
            var anchorMax = content.anchorMax;
            var pivot = content.pivot;
            var anchoredPosition = content.anchoredPosition3D;
            var sizeDelta = content.sizeDelta;
            var localRotation = content.localRotation;
            var localScale = content.localScale;
            var contentObject = content.gameObject;
            bool wasActive = contentObject.activeSelf;
            bool hasGroup = content.TryGetComponent(out CanvasGroup group);
            float alpha = hasGroup ? group.alpha : 1f;

            _canvasRect.sizeDelta = size;
            // Rasterise dynamic text at the capture resolution rather than at one pixel per unit.
            _canvas.scaleFactor = target.width / Mathf.Max(size.x, 1f);
            _camera.orthographicSize = size.y * 0.5f;
            _camera.aspect = size.x / Mathf.Max(size.y, 1f);
            _camera.backgroundColor = background;
            _camera.targetTexture = target;

            content.SetParent(_canvasRect, false);
            content.anchorMin = Vector2.zero;
            content.anchorMax = Vector2.one;
            content.pivot = new Vector2(0.5f, 0.5f);
            content.anchoredPosition3D = Vector3.zero;
            content.sizeDelta = Vector2.zero;
            content.localRotation = Quaternion.identity;
            content.localScale = Vector3.one;
            if (hasGroup)
                group.alpha = 1f;
            if (!wasActive)
                contentObject.SetActive(true);

            try
            {
                LayoutRebuilder.ForceRebuildLayoutImmediate(content);
                Canvas.ForceUpdateCanvases();
                RenderCamera(target);
            }
            finally
            {
                _camera.targetTexture = null;
                if (!wasActive)
                    contentObject.SetActive(false);
                if (hasGroup)
                    group.alpha = alpha;

                content.SetParent(parent, false);
                content.SetSiblingIndex(siblingIndex);
                content.anchorMin = anchorMin;
                content.anchorMax = anchorMax;
                content.pivot = pivot;
                content.anchoredPosition3D = anchoredPosition;
                content.sizeDelta = sizeDelta;
                content.localRotation = localRotation;
                content.localScale = localScale;
            }
        }

        void RenderCamera(RenderTexture target)
        {
#if UNITY_2023_2_OR_NEWER
            if (GraphicsSettings.currentRenderPipeline != null)
            {
                var request = new RenderPipeline.StandardRequest { destination = target };
                if (RenderPipeline.SupportsRenderRequest(_camera, request))
                {
                    RenderPipeline.SubmitRenderRequest(_camera, request);
                    return;
                }
            }
#endif
            _camera.Render();
        }

        public void Dispose()
        {
            if (_rig == null)
                return;
            if (Application.isPlaying)
                Object.Destroy(_rig);
            else
                Object.DestroyImmediate(_rig);
        }
    }
}
