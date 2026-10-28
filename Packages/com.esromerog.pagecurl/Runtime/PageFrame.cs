using UnityEngine;

namespace PageCurl
{
    public enum BookLayout
    {
        SinglePage,
        TwoPageSpread
    }

    /// <summary>Edge the pages are bound on. Left/Right turn with horizontal gestures, Top/Bottom with vertical ones.</summary>
    public enum SpineSide
    {
        Left,
        Right,
        Top,
        Bottom
    }

    /// <summary>
    /// Maps between book space (the book RectTransform's local space) and page space, where x runs from the
    /// spine (0) to the free edge of the turning page (<see cref="Width"/>) and y runs along the spine (0..<see cref="Height"/>).
    /// Every spine side and layout is handled by the curl maths in this single orientation.
    /// </summary>
    public struct PageFrame
    {
        public Vector2 Origin;
        public Vector2 AxisX;
        public Vector2 AxisY;
        public float Width;
        public float Height;

        public Vector2 ToBook(Vector2 point) => Origin + AxisX * point.x + AxisY * point.y;
        public Vector2 DirectionToBook(Vector2 direction) => AxisX * direction.x + AxisY * direction.y;

        public Vector2 FromBook(Vector2 point) => DirectionFromBook(point - Origin);
        public Vector2 DirectionFromBook(Vector2 direction) => new(Vector2.Dot(direction, AxisX), Vector2.Dot(direction, AxisY));

        /// <summary>Slot the turning page lies in before it turns, in book space.</summary>
        public Rect PageRectInBook => BookRect(0f, Width);

        /// <summary>Slot the turning page lands in once it has turned over the spine, in book space.</summary>
        public Rect MirrorRectInBook => BookRect(-Width, 0f);

        public Rect FromBook(Rect rect)
        {
            var a = FromBook(rect.min);
            var b = FromBook(rect.max);
            return Rect.MinMaxRect(Mathf.Min(a.x, b.x), Mathf.Min(a.y, b.y), Mathf.Max(a.x, b.x), Mathf.Max(a.y, b.y));
        }

        Rect BookRect(float fromX, float toX)
        {
            var a = ToBook(new Vector2(fromX, 0f));
            var b = ToBook(new Vector2(toX, Height));
            return Rect.MinMaxRect(Mathf.Min(a.x, b.x), Mathf.Min(a.y, b.y), Mathf.Max(a.x, b.x), Mathf.Max(a.y, b.y));
        }

        public static PageFrame Create(Rect bookRect, SpineSide spine, BookLayout layout)
        {
            bool spread = layout == BookLayout.TwoPageSpread;
            var frame = new PageFrame();
            switch (spine)
            {
                case SpineSide.Left:
                    frame.AxisX = Vector2.right;
                    frame.AxisY = Vector2.up;
                    frame.Origin = new Vector2(spread ? bookRect.center.x : bookRect.xMin, bookRect.yMin);
                    break;
                case SpineSide.Right:
                    frame.AxisX = Vector2.left;
                    frame.AxisY = Vector2.up;
                    frame.Origin = new Vector2(spread ? bookRect.center.x : bookRect.xMax, bookRect.yMin);
                    break;
                case SpineSide.Top:
                    frame.AxisX = Vector2.down;
                    frame.AxisY = Vector2.right;
                    frame.Origin = new Vector2(bookRect.xMin, spread ? bookRect.center.y : bookRect.yMax);
                    break;
                default:
                    frame.AxisX = Vector2.up;
                    frame.AxisY = Vector2.right;
                    frame.Origin = new Vector2(bookRect.xMin, spread ? bookRect.center.y : bookRect.yMin);
                    break;
            }

            bool horizontal = spine == SpineSide.Left || spine == SpineSide.Right;
            float across = horizontal ? bookRect.width : bookRect.height;
            frame.Width = spread ? across * 0.5f : across;
            frame.Height = horizontal ? bookRect.height : bookRect.width;
            return frame;
        }
    }
}
