using System.Collections.Generic;
using UnityEngine;

namespace PageCurl
{
    /// <summary>
    /// Sutherland-Hodgman clipping of convex polygons. Points are xy positions with an extra value in z
    /// (e.g. shadow opacity) that is interpolated along cut edges.
    /// </summary>
    internal static class PolygonClipper
    {
        /// <summary>Keeps the part of the polygon where dot(p.xy, normal) &gt;= offset.</summary>
        public static void Clip(List<Vector3> polygon, List<Vector3> scratch, Vector2 normal, float offset)
        {
            scratch.Clear();
            int count = polygon.Count;
            if (count == 0)
                return;

            var previous = polygon[count - 1];
            float previousSide = normal.x * previous.x + normal.y * previous.y - offset;
            for (int i = 0; i < count; i++)
            {
                var current = polygon[i];
                float side = normal.x * current.x + normal.y * current.y - offset;
                if ((side >= 0f) != (previousSide >= 0f))
                    scratch.Add(Vector3.Lerp(previous, current, previousSide / (previousSide - side)));
                if (side >= 0f)
                    scratch.Add(current);

                previous = current;
                previousSide = side;
            }

            polygon.Clear();
            polygon.AddRange(scratch);
        }

        public static void ClipToRect(List<Vector3> polygon, List<Vector3> scratch, Rect rect)
        {
            Clip(polygon, scratch, Vector2.right, rect.xMin);
            Clip(polygon, scratch, Vector2.left, -rect.xMax);
            Clip(polygon, scratch, Vector2.up, rect.yMin);
            Clip(polygon, scratch, Vector2.down, -rect.yMax);
        }

        public static float SignedArea(List<Vector3> polygon)
        {
            float area = 0f;
            for (int i = 0, j = polygon.Count - 1; i < polygon.Count; j = i++)
                area += polygon[j].x * polygon[i].y - polygon[i].x * polygon[j].y;
            return area * 0.5f;
        }
    }
}
