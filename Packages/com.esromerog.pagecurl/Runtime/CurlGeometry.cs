using UnityEngine;

namespace PageCurl
{
    /// <summary>
    /// Solved shape of a curling page, in page space (see <see cref="PageFrame"/>).
    /// The page wraps around a cylinder lying on the page. Its axis passes through <see cref="Axis"/> along
    /// <see cref="Tangent"/>; everything on the <see cref="Normal"/> side of the axis rolls up and over it.
    /// </summary>
    public struct CurlState
    {
        /// <summary>Point of the flat page that was grabbed.</summary>
        public Vector2 Grab;
        /// <summary>Where the grabbed point currently is, projected onto the page plane.</summary>
        public Vector2 Corner;
        public Vector2 Axis;
        public Vector2 Normal;
        public Vector2 Tangent;
        public float Radius;
        /// <summary>
        /// Cone slope: the radius is multiplied by (1 + Taper * distance along <see cref="Tangent"/> from the grabbed
        /// point). Zero is a cylinder.
        /// </summary>
        public float Taper;
        public float Height;
        /// <summary>0 when the page lies flat on its own side, 1 when it has fully turned over the spine.</summary>
        public float Progress;
    }

    public struct CurlPoint
    {
        /// <summary>Deformed position projected onto the page plane.</summary>
        public Vector2 Position;
        /// <summary>Height above the page plane, towards the viewer.</summary>
        public float Lift;
        /// <summary>Normal of the front face; xy in page space, z towards the viewer.</summary>
        public Vector3 FrontNormal;
        /// <summary>How far the point has rolled around the cylinder, 0..PI. Past PI/2 the back of the page faces the viewer.</summary>
        public float Angle;
    }

    /// <summary>
    /// Page-curl maths. A page is wrapped around a cylinder (as in XBPageCurl and harism's android_page_curl) or, for
    /// corner grabs, around a cone whose radius grows linearly away from the grabbed corner. That is the deformation
    /// of Hong, Card and Chen, "Turning Pages of 3D Electronic Books" (3DUI 2006) behind Apple Books' corner curl,
    /// blended towards a cylinder for grabs near the middle of the edge as in Microsoft's Project Austin.
    /// The axis is solved exactly so the grabbed point stays under the finger, and the radius shrinks so the page
    /// lands flat once fully turned.
    /// </summary>
    public static class CurlGeometry
    {
        const float Epsilon = 1e-5f;
        // sin(60 degrees): the steepest the fold may lean away from parallel to the free edge.
        const float MaxTiltSin = 0.866f;
        // The cone never narrows below this fraction of the base radius.
        const float MinConeRatio = 0.25f;

        /// <summary>
        /// Keeps a dragged corner where a sheet bound at the spine can physically reach: no further from either end of
        /// the spine than the grabbed point was, and never pulled outwards past its resting position.
        /// </summary>
        public static Vector2 ConstrainCorner(Vector2 grab, Vector2 corner, float height)
        {
            var bottom = Vector2.zero;
            var top = new Vector2(0f, height);
            float bottomReach = Vector2.Distance(grab, bottom);
            float topReach = Vector2.Distance(grab, top);

            // Alternating projections onto the two discs converge to a point inside both.
            for (int i = 0; i < 8; i++)
            {
                corner = ClampToDisc(corner, bottom, bottomReach);
                corner = ClampToDisc(corner, top, topReach);
            }

            corner.x = Mathf.Clamp(corner.x, -grab.x, grab.x);
            return corner;
        }

        public static CurlState Solve(Vector2 grab, Vector2 corner, float height, float radius, float taper, bool keepSpineFlat)
        {
            var state = new CurlState
            {
                Grab = grab,
                Corner = corner,
                Axis = grab,
                Normal = Vector2.right,
                Tangent = Vector2.up,
                Radius = Mathf.Max(radius, 0f),
                Height = Mathf.Max(height, Epsilon),
                Progress = grab.x > Epsilon ? Mathf.Clamp01((grab.x - corner.x) / (2f * grab.x)) : 0f
            };

            var delta = grab - corner;
            if (delta.magnitude < Epsilon)
                return state;

            var normal = LimitTilt(delta.normalized, delta.magnitude, grab.y, state.Height);
            // With the tilt limited the grabbed point moves along the curl normal only, landing as close to the
            // corner as it can.
            float distance = Mathf.Max(Vector2.Dot(delta, normal), 0f);
            corner = grab - normal * distance;
            state.Corner = corner;
            state.Progress = grab.x > Epsilon ? Mathf.Clamp01((grab.x - corner.x) / (2f * grab.x)) : 0f;
            if (distance < Epsilon)
                return state;

            // Fully turned, the grabbed point sits mirrored across the spine, 2 * grab.x away. Shrink the curl on the
            // way there so the page arrives flat instead of popping.
            float r = Mathf.Min(state.Radius, Mathf.Max(2f * grab.x - distance, 0f) / Mathf.PI);

            // A tight corner pull would otherwise roll paper off the spine. A smaller radius moves the axis away
            // from the spine, so find the largest radius that keeps both spine ends flat.
            if (keepSpineFlat && SpineLift(corner, normal, distance, r, height) > 0f)
            {
                float low = 0f, high = r;
                for (int i = 0; i < 16; i++)
                {
                    float mid = (low + high) * 0.5f;
                    if (SpineLift(corner, normal, distance, mid, height) > 0f)
                        high = mid;
                    else
                        low = mid;
                }
                r = low;
            }

            state.Radius = r;
            state.Normal = normal;
            state.Tangent = new Vector2(-normal.y, normal.x);

            // Cone only for grabs towards a corner, opening towards the far end of the edge. The tangent always points
            // up the page (its y is normal.x, which the tilt limit keeps positive).
            float cornerness = Mathf.Abs(2f * grab.y / state.Height - 1f);
            float side = grab.y < state.Height * 0.5f ? 1f : -1f;
            state.Taper = Mathf.Max(taper, 0f) * cornerness * side / state.Height;
            state.Axis = corner + normal * AxisOffset(distance, r);

            // Guard against the corner constraint converging only approximately: never let the spine roll.
            if (keepSpineFlat)
            {
                float lift = SpineLift(corner, normal, distance, r, height);
                if (lift > 0f)
                    state.Axis += normal * lift;
            }
            return state;
        }

        /// <summary>
        /// Paper lifted at one point bends there first: the grabbed point should be the most-rolled part of the page.
        /// Tilting the fold rolls the free edge on one side of the grab further than the grab itself, so that
        /// extra roll is limited to the distance pulled so far. A corner grab has no paper beyond it and can peel
        /// diagonally at once; a grab mid-edge starts with a straight fold and twists as it is pulled further.
        /// </summary>
        static Vector2 LimitTilt(Vector2 direction, float distance, float grabY, float height)
        {
            // Never let the fold swing towards parallel with the spine: it would have to run through the spine,
            // and near there the fold direction becomes hypersensitive to tiny finger movements.
            float maxSin = MaxTiltSin;
            float beyond = direction.y > 0f ? height - grabY : grabY;
            if (beyond > Epsilon)
                maxSin = Mathf.Min(maxSin, distance / beyond);

            if (Mathf.Abs(direction.y) <= maxSin)
                return direction;
            return new Vector2(Mathf.Sqrt(1f - maxSin * maxSin), Mathf.Sign(direction.y) * maxSin);
        }

        public static float RadiusAt(in CurlState state, Vector2 point) =>
            RadiusAlong(state, Vector2.Dot(point - state.Grab, state.Tangent));

        /// <summary>Cone radius at a signed distance along the axis from the grabbed point.</summary>
        public static float RadiusAlong(in CurlState state, float alongFromGrab) =>
            state.Radius * Mathf.Max(MinConeRatio, 1f + state.Taper * alongFromGrab);

        public static CurlPoint Deform(in CurlState state, Vector2 point)
        {
            var relative = point - state.Axis;
            float u = Vector2.Dot(relative, state.Normal);
            float v = Vector2.Dot(relative, state.Tangent);
            float radius = RadiusAt(state, point);

            CurlPoint result;
            float across;
            if (u <= 0f)
            {
                // Still lying flat.
                across = u;
                result.Lift = 0f;
                result.FrontNormal = new Vector3(0f, 0f, 1f);
                result.Angle = 0f;
            }
            else if (u < Mathf.PI * radius)
            {
                // Rolled onto the cylinder; arc length u becomes angle u / r.
                float angle = u / radius;
                float sin = Mathf.Sin(angle);
                float cos = Mathf.Cos(angle);
                across = radius * sin;
                result.Lift = radius * (1f - cos);
                result.FrontNormal = new Vector3(-state.Normal.x * sin, -state.Normal.y * sin, cos);
                result.Angle = angle;
            }
            else
            {
                // Past the top of the cylinder: the flap lies flat, upside down, on top of the page.
                across = Mathf.PI * radius - u;
                result.Lift = 2f * radius;
                result.FrontNormal = new Vector3(0f, 0f, -1f);
                result.Angle = Mathf.PI;
            }

            result.Position = state.Axis + state.Normal * across + state.Tangent * v;
            return result;
        }

        /// <summary>
        /// Signed distance from the dragged corner to the cylinder axis, along the curl normal, that lands the
        /// grabbed point exactly on the corner.
        /// </summary>
        static float AxisOffset(float distance, float radius)
        {
            // The grabbed point has rolled past the top: it lands flat at axis - (u - PI r), with u = distance - offset.
            if (distance >= Mathf.PI * radius)
                return (distance - Mathf.PI * radius) * 0.5f;

            // Still on the cylinder at angle a, projected at axis + r sin(a). Solving gives distance = r (a - sin a).
            float angle = SolveRollAngle(distance / radius);
            return -radius * Mathf.Sin(angle);
        }

        /// <summary>Solves a - sin(a) = k for a in [0, PI].</summary>
        static float SolveRollAngle(float k)
        {
            // a - sin(a) ~ a^3 / 6 near zero gives a starting point just below the root; Newton then converges fast.
            float angle = Mathf.Min(Mathf.Pow(6f * k, 1f / 3f), Mathf.PI);
            for (int i = 0; i < 8; i++)
            {
                float slope = 1f - Mathf.Cos(angle);
                if (slope < 1e-6f)
                    break;
                angle = Mathf.Clamp(angle - (angle - Mathf.Sin(angle) - k) / slope, 0f, Mathf.PI);
            }
            return angle;
        }

        /// <summary>How far past the curl axis the furthest spine end is. Positive means the spine would lift.</summary>
        static float SpineLift(Vector2 corner, Vector2 normal, float distance, float radius, float height)
        {
            var axis = corner + normal * AxisOffset(distance, radius);
            float bottom = Vector2.Dot(-axis, normal);
            float top = Vector2.Dot(new Vector2(0f, height) - axis, normal);
            return Mathf.Max(bottom, top);
        }

        static Vector2 ClampToDisc(Vector2 point, Vector2 center, float radius)
        {
            var offset = point - center;
            float length = offset.magnitude;
            return length > radius && length > Epsilon ? center + offset * (radius / length) : point;
        }
    }
}
