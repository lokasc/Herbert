using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.UI;

namespace PageCurl
{
    public enum BackFace
    {
        /// <summary>The front shows faintly through the paper, mirrored, like Apple Books.</summary>
        SeeThrough,
        /// <summary>A fixed texture, e.g. a page-back pattern.</summary>
        Texture
    }

    [Serializable]
    public class BookPage
    {
        [Tooltip("UI drawn on this page. It stays live and interactive while the book is at rest and is captured to a texture while the page turns. It should be a child of the book.")]
        public RectTransform content;

        [Tooltip("Used when there is no content. Leave both empty for a blank page.")]
        public Texture texture;
    }

    /// <summary>
    /// A book of uGUI pages turned with a physical page curl. Put it on a RectTransform inside any Canvas
    /// (Overlay, Screen Space Camera or World Space). Add <see cref="PageCurlInput"/> for drag, tap and key input,
    /// or drive it from code with <see cref="NextPage"/>, <see cref="PreviousPage"/> and the drag methods.
    /// </summary>
    [DisallowMultipleComponent]
    [RequireComponent(typeof(RectTransform))]
    [AddComponentMenu("UI/Page Curl/Page Curl Book")]
    public class PageCurlBook : MonoBehaviour
    {
        enum TurnState
        {
            Idle,
            Dragging,
            Settling,
            Auto
        }

        const string ShaderResource = "PageCurl/UI-PageCurl";
        static readonly int PaperColorId = Shader.PropertyToID("_PaperColor");
        static readonly int BackTintId = Shader.PropertyToID("_BackTint");
        static readonly int SeeThroughId = Shader.PropertyToID("_SeeThrough");
        static readonly int UseBackTexId = Shader.PropertyToID("_UseBackTex");
        static readonly int ShadowColorId = Shader.PropertyToID("_ShadowColor");
        static readonly int HighlightColorId = Shader.PropertyToID("_HighlightColor");

        [Header("Pages")]
        [SerializeField] List<BookPage> pages = new();
        [SerializeField, Min(0)] int startPage;

        [Header("Layout")]
        [SerializeField] BookLayout layout = BookLayout.SinglePage;
        [Tooltip("Edge the pages are bound on. Left/Right turn with horizontal gestures, Top/Bottom with vertical gestures. Right is for right-to-left books.")]
        [SerializeField] SpineSide spine = SpineSide.Left;
        [Tooltip("Clip pages and the curl to this rect (adds a RectMask2D). With a single page this hides the turned page as it leaves past the spine.")]
        [SerializeField] bool clipToBounds = true;

        [Header("Curl Shape")]
        [Tooltip("Radius of the curl as a fraction of the page width.")]
        [SerializeField, Range(0.02f, 0.5f)] float curlRadius = 0.14f;
        [Tooltip("Corner grabs wrap the page around a cone that widens away from the grabbed corner, like Apple Books. 0 is always a straight cylinder (Kindle). Grabs near the middle of the edge stay cylindrical.")]
        [SerializeField, Range(0f, 3f)] float coneTaper = 1f;
        [Tooltip("Scales how far the curl lifts towards the camera. Only visible with perspective canvas cameras and ignored on Screen Space Overlay canvases; lighting is unaffected.")]
        [SerializeField, Range(0f, 2f)] float liftScale = 1f;
        [Tooltip("Mesh slices across the curl. More is smoother.")]
        [SerializeField, Range(8, 64)] int curlSegments = 24;
        [Tooltip("Mesh slices along the curl, used when Cone Taper is above zero.")]
        [SerializeField, Range(1, 24)] int taperSegments = 8;
        [Tooltip("Keep the corner where paper bound at the spine can reach, and never lift the spine.")]
        [SerializeField] bool constrainToPaper = true;

        [Header("Paper")]
        [SerializeField] Color paperColor = new(0.98f, 0.97f, 0.94f, 1f);
        [Tooltip("Single page layout: what the back of a turning page shows. Spreads always show the following page.")]
        [SerializeField] BackFace backFace = BackFace.SeeThrough;
        [Tooltip("How strongly the front shows through on the back of the page.")]
        [SerializeField, Range(0f, 1f)] float seeThrough = 0.2f;
        [SerializeField] Texture backTexture;
        [SerializeField] Color backTint = new(0.95f, 0.94f, 0.92f, 1f);

        [Header("Lighting")]
        [Tooltip("Direction the light comes from, in book space. Z points at the viewer.")]
        [SerializeField] Vector3 lightDirection = new(-0.3f, 0.45f, 1f);
        [SerializeField, Range(0f, 1f)] float ambient = 0.4f;
        [Tooltip("Strength of the glossy highlight along the curl.")]
        [SerializeField, Range(0f, 1f)] float highlight = 0.2f;
        [SerializeField, Range(1f, 128f)] float highlightPower = 20f;
        [SerializeField] Color highlightColor = Color.white;
        [Tooltip("Colour of the soft shadows; alpha is their opacity.")]
        [SerializeField] Color shadowColor = new(0f, 0f, 0f, 0.45f);
        [Tooltip("Width of the soft shadows as a fraction of the page width.")]
        [SerializeField, Range(0f, 0.5f)] float shadowWidth = 0.12f;
        [Tooltip("Offset of the lifted flap's shadow in book space, as a fraction of the page width.")]
        [SerializeField] Vector2 shadowOffset = new(0.01f, -0.015f);

        [Header("Feel")]
        [Tooltip("How much dragging along the spine twists the page. 0 keeps the fold parallel to the spine like Kindle, 1 lets the corner follow the finger like Apple Books.")]
        [SerializeField, Range(0f, 1f)] float cornerFreedom = 1f;
        [Tooltip("Fraction of a turn past which releasing the drag completes it.")]
        [SerializeField, Range(0.05f, 0.95f)] float completeThreshold = 0.2f;
        [Tooltip("Release speed, in page widths per second, that completes or cancels a turn regardless of position.")]
        [SerializeField, Min(0f)] float flickSpeed = 1.2f;
        [Tooltip("Lag of the page behind the finger. 0 sticks exactly to it.")]
        [SerializeField, Min(0f)] float dragSmoothTime = 0.04f;
        [Tooltip("How quickly a released page falls into place.")]
        [SerializeField, Min(0.01f)] float releaseSmoothTime = 0.1f;
        [Tooltip("Duration of turns started by keys, taps or code.")]
        [SerializeField, Min(0.05f)] float autoTurnDuration = 0.6f;
        [SerializeField] AnimationCurve autoTurnCurve = AnimationCurve.EaseInOut(0f, 0f, 1f, 1f);
        [Tooltip("Where along the free edge automatic turns grab the page: 0 is the start of the spine (bottom for a Left spine), 1 the end.")]
        [SerializeField, Range(0f, 1f)] float autoTurnGrab = 0.2f;
        [Tooltip("How far the grabbed corner lifts along the spine during an automatic turn, as a fraction of the page height. 0 turns with a straight fold.")]
        [SerializeField, Range(-0.5f, 0.5f)] float autoTurnArc = 0.15f;
        [SerializeField] bool useUnscaledTime = true;

        [Header("Capture")]
        [Tooltip("Resolution of captured pages relative to their size on screen.")]
        [SerializeField, Range(0.25f, 2f)] float captureScale = 1f;
        [Tooltip("Capture UI pages again at the start of every turn. Turn off for static pages and call MarkDirty when one changes.")]
        [SerializeField] bool recaptureEveryTurn = true;
        [Tooltip("Layer used by the hidden capture camera and canvas.")]
        [SerializeField] int captureLayer = 5;

        [Header("Events")]
        [Tooltip("Index of the first visible page after a turn or jump.")]
        public UnityEvent<int> onPageChanged = new();
        [Tooltip("+1 for a forward turn, -1 for a backward one.")]
        public UnityEvent<int> onTurnStarted = new();
        [Tooltip("True when the page turned, false when the turn was cancelled.")]
        public UnityEvent<bool> onTurnEnded = new();
        [Tooltip("0 while the turning page lies on its own side, 1 once it has fully turned over.")]
        public UnityEvent<float> onTurnProgress = new();

        RectTransform _rect;
        Canvas _canvas;
        PageFrame _frame;
        RawImage _underPage;
        RawImage _underFacing;
        PageCurlGraphic _curl;
        Material _material;
        Texture2D _blank;
        PageCapture _capture;
        readonly Dictionary<int, RenderTexture> _captures = new();
        readonly List<RenderTexture> _texturePool = new();
        readonly HashSet<int> _dirty = new();
        readonly HashSet<int> _turnPages = new();
        readonly List<int> _released = new();
        bool _initialized;
        bool _settingsChanged;
        bool _idleRefreshPending;

        int _leaf;
        TurnState _state;
        int _direction;
        int _turningLeaf;
        int _queued;
        Vector2 _grab;
        Vector2 _corner;
        Vector2 _cornerVelocity;
        Vector2 _target;
        Vector2 _dragOrigin;
        Vector2 _cornerOrigin;
        float _dragScale;
        float _autoTime;
        bool _settleToTurned;
        float _progress;

        public IReadOnlyList<BookPage> Pages => pages;
        public int PageCount => pages.Count;
        public BookLayout Layout => layout;
        public SpineSide Spine => spine;
        /// <summary>Page space of the turning page; see <see cref="PageFrame"/>.</summary>
        public PageFrame Frame => _frame;
        public bool IsTurning => _state != TurnState.Idle;
        public bool IsDragging => _state == TurnState.Dragging;
        /// <summary>0 while the turning page lies on its own side, 1 once it has fully turned over.</summary>
        public float TurnProgress => _progress;
        /// <summary>Index of the first visible page: the page in single layout, the left page of a spread.</summary>
        public int CurrentPage => layout == BookLayout.SinglePage ? _leaf : Mathf.Max(0, 2 * _leaf - 1);
        public bool CanTurnForward => CanTurn(1);
        public bool CanTurnBackward => CanTurn(-1);

        bool Spread => layout == BookLayout.TwoPageSpread;

        // Set up in Start rather than Awake: it reparents page contents, which Unity refuses to do while a
        // hierarchy is being activated.
        void Start() => Initialize();

        void OnEnable()
        {
            // Children can't be toggled while this hierarchy is being (de)activated, so refresh on the next Update.
            _idleRefreshPending = _initialized;
        }

        void OnDisable()
        {
            // Cancel any turn; the display is reset once re-enabled.
            _state = TurnState.Idle;
            _queued = 0;
        }

        void OnDestroy()
        {
            if (_material != null)
                Destroy(_material);
            if (_blank != null)
                Destroy(_blank);
            foreach (var texture in _captures.Values)
                DestroyTexture(texture);
            foreach (var texture in _texturePool)
                DestroyTexture(texture);
            _captures.Clear();
            _texturePool.Clear();
            _capture?.Dispose();
            _capture = null;
        }

        void OnRectTransformDimensionsChange()
        {
            if (_initialized)
                _frame = PageFrame.Create(_rect.rect, spine, layout);
        }

#if UNITY_EDITOR
        void OnValidate()
        {
            // Applied on the next Update; OnValidate may not touch the hierarchy.
            if (Application.isPlaying && _initialized)
                _settingsChanged = true;
        }
#endif

        void Initialize()
        {
            if (_initialized)
                return;

            _rect = (RectTransform)transform;
            _canvas = GetComponentInParent<Canvas>();
            if (_canvas == null)
                Debug.LogWarning($"{nameof(PageCurlBook)} on '{name}' needs to be inside a Canvas.", this);

            var shader = Resources.Load<Shader>(ShaderResource);
            if (shader == null)
            {
                Debug.LogError($"{nameof(PageCurlBook)}: shader resource '{ShaderResource}' is missing.", this);
                enabled = false;
                return;
            }

            _initialized = true;
            _material = new Material(shader) { name = "Page Curl (Instance)", hideFlags = HideFlags.HideAndDontSave };
            _underFacing = CreateSlot("[Page Curl] Facing Page");
            _underPage = CreateSlot("[Page Curl] Page");
            _curl = CreateCurl();
            if (clipToBounds && !TryGetComponent<RectMask2D>(out _))
                gameObject.AddComponent<RectMask2D>();

            ApplyStyle();
            Relayout();
            _leaf = ClampLeaf(LeafForPage(startPage));
            ShowIdle();
        }

        void Update()
        {
            if (!_initialized)
                return;

            if (_settingsChanged)
            {
                _settingsChanged = false;
                ApplyStyle();
                if (_state == TurnState.Idle)
                {
                    Relayout();
                    _idleRefreshPending = true;
                }
            }

            if (_idleRefreshPending && _state == TurnState.Idle)
            {
                _idleRefreshPending = false;
                ShowIdle();
            }

            if (_state == TurnState.Idle)
                return;

            _frame = PageFrame.Create(_rect.rect, spine, layout);
            float deltaTime = useUnscaledTime ? Time.unscaledDeltaTime : Time.deltaTime;
            switch (_state)
            {
                case TurnState.Dragging:
                    _corner = Vector2.SmoothDamp(_corner, _target, ref _cornerVelocity, dragSmoothTime, Mathf.Infinity, deltaTime);
                    break;

                case TurnState.Settling:
                    _corner = Vector2.SmoothDamp(_corner, _target, ref _cornerVelocity, releaseSmoothTime, Mathf.Infinity, deltaTime);
                    // At 1% of the page width the curl radius is already near zero, so snapping is invisible.
                    float tolerance = 0.01f * _frame.Width;
                    if ((_corner - _target).sqrMagnitude <= tolerance * tolerance)
                    {
                        FinishTurn(_settleToTurned == _direction > 0);
                        return;
                    }
                    break;

                case TurnState.Auto:
                    _autoTime += deltaTime / autoTurnDuration;
                    _corner = AutoCorner(_autoTime);
                    if (_autoTime >= 1f)
                    {
                        FinishTurn(true);
                        return;
                    }
                    break;
            }

            RefreshCurl();
        }

        /// <summary>Turns to the next page (or spread) with an animation. Returns false if there is none.</summary>
        public bool NextPage() => Turn(1);

        /// <summary>Turns to the previous page (or spread) with an animation. Returns false if there is none.</summary>
        public bool PreviousPage() => Turn(-1);

        /// <summary>Animated turn; +1 forward, -1 backward. A turn requested mid-animation is queued.</summary>
        public bool Turn(int direction)
        {
            if (!_initialized || _state == TurnState.Dragging)
                return false;

            direction = direction >= 0 ? 1 : -1;
            if (_state != TurnState.Idle)
            {
                _queued = direction;
                return true;
            }
            if (!CanTurn(direction))
                return false;

            _frame = PageFrame.Create(_rect.rect, spine, layout);
            _grab = new Vector2(_frame.Width, autoTurnGrab * _frame.Height);
            _autoTime = 0f;
            PrepareTurn(direction);
            _state = TurnState.Auto;
            _corner = AutoCorner(0f);
            RefreshCurl();
            return true;
        }

        /// <summary>Jumps to a page without animating.</summary>
        public void GoToPage(int page)
        {
            if (!_initialized)
            {
                startPage = Mathf.Max(0, page);
                return;
            }
            if (_state != TurnState.Idle)
                FinishTurn(false, notify: false);

            _queued = 0;
            _leaf = ClampLeaf(LeafForPage(page));
            ShowIdle();
            onPageChanged.Invoke(CurrentPage);
        }

        /// <summary>
        /// Starts a manual turn at a point in book space (the book RectTransform's local space).
        /// +1 pulls the current page towards the spine, -1 brings the previous page back.
        /// </summary>
        public bool BeginDrag(Vector2 localPoint, int direction)
        {
            if (!_initialized || _state == TurnState.Dragging)
                return false;
            if (_state != TurnState.Idle)
                FinishInFlightTurn();

            direction = direction >= 0 ? 1 : -1;
            if (!CanTurn(direction))
                return false;

            _frame = PageFrame.Create(_rect.rect, spine, layout);
            var point = _frame.FromBook(localPoint);
            _grab = new Vector2(_frame.Width, Mathf.Clamp(point.y, 0f, _frame.Height));
            _dragOrigin = point;
            // A single page coming back starts off-screen past the spine, so it moves twice as fast to keep its
            // edge under the finger.
            _dragScale = direction > 0 || Spread ? 1f : 2f;
            _cornerOrigin = direction > 0 ? _grab : Mirror(_grab);
            _corner = _target = _cornerOrigin;
            _cornerVelocity = Vector2.zero;
            _queued = 0;

            PrepareTurn(direction);
            _state = TurnState.Dragging;
            RefreshCurl();
            return true;
        }

        /// <summary>Moves a manual turn to a point in book space.</summary>
        public void Drag(Vector2 localPoint)
        {
            if (_state != TurnState.Dragging)
                return;

            var delta = _frame.FromBook(localPoint) - _dragOrigin;
            _target = Constrain(_cornerOrigin + new Vector2(delta.x * _dragScale, delta.y * cornerFreedom));
        }

        /// <summary>Releases a manual turn. The page completes or falls back depending on position and speed.</summary>
        /// <param name="localVelocity">Pointer velocity in book space units per second.</param>
        public void EndDrag(Vector2 localVelocity)
        {
            if (_state != TurnState.Dragging)
                return;

            var velocity = _frame.DirectionFromBook(localVelocity);
            // Page widths per second; negative moves towards the spine, i.e. turns the page over.
            float speed = velocity.x / Mathf.Max(_frame.Width, 1e-3f);
            float turned = TurnedFraction(_target);

            if (_direction > 0)
                _settleToTurned = speed < -flickSpeed || (speed <= flickSpeed && turned > completeThreshold);
            else
                _settleToTurned = !(speed > flickSpeed || (speed >= -flickSpeed && turned < 1f - completeThreshold));

            _target = _settleToTurned ? Mirror(_grab) : _grab;
            _cornerVelocity = new Vector2(velocity.x * _dragScale, velocity.y * cornerFreedom);
            _state = TurnState.Settling;
        }

        /// <summary>Recaptures a UI page the next time it is shown turning.</summary>
        public void MarkDirty(int page) => _dirty.Add(page);

        public void MarkAllDirty()
        {
            for (int i = 0; i < pages.Count; i++)
                _dirty.Add(i);
        }

        /// <summary>Replaces all pages. UI contents are reparented under the book.</summary>
        public void SetPages(IEnumerable<BookPage> newPages, int page = 0)
        {
            if (_initialized && _state != TurnState.Idle)
                FinishTurn(false, notify: false);

            pages = new List<BookPage>(newPages);
            ReleaseCaptures(null);
            MarkAllDirty();
            if (!_initialized)
            {
                startPage = page;
                return;
            }

            Relayout();
            _leaf = ClampLeaf(LeafForPage(page));
            ShowIdle();
            onPageChanged.Invoke(CurrentPage);
        }

        [ContextMenu("Collect Pages From Children")]
        void CollectPagesFromChildren()
        {
            pages.Clear();
            foreach (Transform child in transform)
            {
                if (child is RectTransform rectChild && !child.name.StartsWith("[Page Curl]"))
                    pages.Add(new BookPage { content = rectChild });
            }
        }

        bool CanTurn(int direction)
        {
            if (pages.Count == 0)
                return false;
            if (direction < 0)
                return _leaf > 0;
            // Forward needs something to reveal: the next page, or the back of this leaf in a spread.
            return Spread ? 2 * _leaf + 1 < pages.Count : _leaf + 1 < pages.Count;
        }

        // A leaf is one sheet of paper: in a single layout it is one page; in a spread its front is the right page
        // (even index) and its back the left page of the following spread (odd index). Spread k shows the back of
        // leaf k - 1 on the left and the front of leaf k on the right.
        int FrontPage(int leaf) => leaf < 0 ? -1 : Spread ? 2 * leaf : leaf;
        int BackPage(int leaf) => leaf < 0 || !Spread ? -1 : 2 * leaf + 1;
        int LeafForPage(int page) => Spread ? (Mathf.Max(page, 0) + 1) / 2 : Mathf.Max(page, 0);
        int ClampLeaf(int leaf) => Mathf.Clamp(leaf, 0, Spread ? pages.Count / 2 : Mathf.Max(pages.Count - 1, 0));
        bool IsValid(int page) => page >= 0 && page < pages.Count;
        RectTransform ContentOf(int page) => pages[page]?.content;

        static Vector2 Mirror(Vector2 point) => new(-point.x, point.y);

        float TurnedFraction(Vector2 corner) => _grab.x > 1e-5f ? Mathf.Clamp01((_grab.x - corner.x) / (2f * _grab.x)) : 0f;

        Vector2 Constrain(Vector2 corner)
        {
            if (constrainToPaper)
                return CurlGeometry.ConstrainCorner(_grab, corner, _frame.Height);
            corner.x = Mathf.Clamp(corner.x, -_grab.x, _grab.x);
            return corner;
        }

        Vector2 AutoCorner(float time)
        {
            float eased = autoTurnCurve.Evaluate(Mathf.Clamp01(time));
            float turned = _direction > 0 ? eased : 1f - eased;
            float arc = autoTurnArc * _frame.Height * Mathf.Sin(turned * Mathf.PI);
            return Constrain(new Vector2(Mathf.Lerp(_grab.x, -_grab.x, turned), _grab.y + arc));
        }

        void PrepareTurn(int direction)
        {
            _direction = direction;
            _turningLeaf = direction > 0 ? _leaf : _leaf - 1;

            int front = FrontPage(_turningLeaf);
            int back = BackPage(_turningLeaf);
            int under = FrontPage(direction > 0 ? _leaf + 1 : _leaf);
            int facing = Spread ? BackPage(direction > 0 ? _leaf - 1 : _leaf - 2) : -1;

            _turnPages.Clear();
            _turnPages.Add(front);
            _turnPages.Add(back);
            _turnPages.Add(under);
            _turnPages.Add(facing);
            ReleaseCaptures(_turnPages);

            // Live UI hides while its captured image stands in for it.
            int restingFront = FrontPage(_leaf);
            int restingFacing = Spread ? BackPage(_leaf - 1) : -1;
            for (int i = 0; i < pages.Count; i++)
                SetContentState(i, i == restingFront || i == restingFacing, false);

            ShowSlot(_underPage, under, live: false);
            ShowSlot(_underFacing, facing, live: false);

            Texture backSide = Spread
                ? (IsValid(back) ? TextureFor(back) : _blank)
                : backFace == BackFace.Texture ? backTexture : null;
            _curl.SetTextures(TextureFor(front), backSide);
            _curl.gameObject.SetActive(true);
            _curl.transform.SetAsLastSibling();

            onTurnStarted.Invoke(direction);
        }

        void FinishInFlightTurn()
        {
            if (_state == TurnState.Settling)
                FinishTurn(_settleToTurned == _direction > 0);
            else if (_state == TurnState.Auto)
                FinishTurn(true);
        }

        void FinishTurn(bool completed, bool notify = true)
        {
            if (completed)
                _leaf = ClampLeaf(_leaf + _direction);
            ShowIdle();

            if (!notify)
            {
                _queued = 0;
                return;
            }

            onTurnEnded.Invoke(completed);
            if (completed)
                onPageChanged.Invoke(CurrentPage);

            if (_queued != 0)
            {
                int queued = _queued;
                _queued = 0;
                Turn(queued);
            }
        }

        void ShowIdle()
        {
            _state = TurnState.Idle;
            _progress = 0f;
            _curl.gameObject.SetActive(false);

            int front = FrontPage(_leaf);
            int facing = Spread ? BackPage(_leaf - 1) : -1;
            ShowSlot(_underPage, front, live: true);
            ShowSlot(_underFacing, facing, live: true);
            for (int i = 0; i < pages.Count; i++)
            {
                bool visible = i == front || i == facing;
                SetContentState(i, visible, visible);
            }
        }

        void ShowSlot(RawImage slot, int page, bool live)
        {
            if (!IsValid(page))
            {
                slot.enabled = false;
                return;
            }

            // Live UI pages draw over a sheet of paper; otherwise the slot shows the page's image.
            slot.texture = live && ContentOf(page) != null ? _blank : TextureFor(page);
            slot.color = Color.white;
            slot.enabled = true;
        }

        void SetContentState(int page, bool active, bool visible)
        {
            var content = ContentOf(page);
            if (content == null)
                return;

            if (content.gameObject.activeSelf != active)
                content.gameObject.SetActive(active);
            if (!content.TryGetComponent(out CanvasGroup group))
                group = content.gameObject.AddComponent<CanvasGroup>();
            group.alpha = visible ? 1f : 0f;
            group.interactable = visible;
            group.blocksRaycasts = visible;
        }

        void RefreshCurl()
        {
            float width = _frame.Width;
            var corner = Constrain(_corner);
            var curl = CurlGeometry.Solve(_grab, corner, _frame.Height, curlRadius * width, coneTaper, constrainToPaper);
            _progress = curl.Progress;

            var settings = new PageCurlGraphic.Settings
            {
                Frame = _frame,
                Curl = curl,
                Bounds = _frame.FromBook(_rect.rect),
                BaseRadius = curlRadius * width,
                CurlSegments = curlSegments,
                TaperSegments = taperSegments,
                // Overlay canvases are orthographic, so lifting only risks depth clipping; draw order already
                // handles what is in front.
                LiftScale = _canvas != null && _canvas.rootCanvas.renderMode == RenderMode.ScreenSpaceOverlay ? 0f : liftScale,
                ShadowWidth = shadowWidth * width,
                ShadowOffset = _frame.DirectionFromBook(shadowOffset * width),
                LightDirection = lightDirection,
                Ambient = ambient,
                Highlight = highlight,
                HighlightPower = highlightPower
            };
            _curl.SetCurl(settings);
            onTurnProgress.Invoke(_progress);
        }

        void Relayout()
        {
            _frame = PageFrame.Create(_rect.rect, spine, layout);
            Place((RectTransform)_underPage.transform, _frame.PageRectInBook);
            Place((RectTransform)_underFacing.transform, _frame.MirrorRectInBook);

            for (int i = 0; i < pages.Count; i++)
            {
                var content = ContentOf(i);
                if (content == null)
                    continue;
                if (content.parent != transform)
                    content.SetParent(transform, false);
                Place(content, SlotFor(i));
            }

            _underFacing.transform.SetAsFirstSibling();
            _underPage.transform.SetSiblingIndex(1);
            var curlRect = (RectTransform)_curl.transform;
            curlRect.pivot = _rect.pivot;
            curlRect.SetAsLastSibling();
        }

        Rect SlotFor(int page) => Spread && page % 2 == 1 ? _frame.MirrorRectInBook : _frame.PageRectInBook;

        void Place(RectTransform target, Rect slot)
        {
            var bounds = _rect.rect;
            var size = new Vector2(Mathf.Max(bounds.width, 1e-5f), Mathf.Max(bounds.height, 1e-5f));
            target.anchorMin = (slot.min - bounds.min) / size;
            target.anchorMax = (slot.max - bounds.min) / size;
            target.offsetMin = Vector2.zero;
            target.offsetMax = Vector2.zero;
            target.localRotation = Quaternion.identity;
            target.localScale = Vector3.one;
        }

        void ApplyStyle()
        {
            _material.SetColor(PaperColorId, paperColor);
            _material.SetColor(BackTintId, Spread ? Color.white : backTint);
            _material.SetFloat(SeeThroughId, seeThrough);
            _material.SetFloat(UseBackTexId, Spread || backFace == BackFace.Texture ? 1f : 0f);
            _material.SetColor(ShadowColorId, shadowColor);
            _material.SetColor(HighlightColorId, highlightColor);

            if (_blank == null)
                _blank = new Texture2D(2, 2, TextureFormat.RGBA32, false) { name = "Page Curl Paper", hideFlags = HideFlags.HideAndDontSave };
            var pixels = _blank.GetPixels32();
            for (int i = 0; i < pixels.Length; i++)
                pixels[i] = paperColor;
            _blank.SetPixels32(pixels);
            _blank.Apply();
        }

        Texture TextureFor(int page)
        {
            var entry = pages[page];
            if (entry?.content != null)
                return Capture(page);
            return entry?.texture != null ? entry.texture : _blank;
        }

        Texture Capture(int page)
        {
            var slot = SlotFor(page);
            var size = CaptureSize(slot);
            _captures.TryGetValue(page, out var texture);
            if (texture != null && texture.width == size.x && texture.height == size.y && !_dirty.Contains(page) && !recaptureEveryTurn)
                return texture;

            if (texture == null || texture.width != size.x || texture.height != size.y)
            {
                if (texture != null)
                    _texturePool.Add(texture);
                texture = RentTexture(size);
                _captures[page] = texture;
            }

            _capture ??= new PageCapture(captureLayer);
            _capture.Render(ContentOf(page), texture, slot.size, paperColor);
            _dirty.Remove(page);
            return texture;
        }

        /// <summary>Returns captures not in <paramref name="keep"/> to the pool so memory stays bounded by a few pages.</summary>
        void ReleaseCaptures(HashSet<int> keep)
        {
            _released.Clear();
            foreach (var pair in _captures)
            {
                if (keep == null || !keep.Contains(pair.Key))
                    _released.Add(pair.Key);
            }
            foreach (int page in _released)
            {
                _texturePool.Add(_captures[page]);
                _captures.Remove(page);
                _dirty.Add(page);
            }
            while (_texturePool.Count > 4)
            {
                DestroyTexture(_texturePool[0]);
                _texturePool.RemoveAt(0);
            }
        }

        RenderTexture RentTexture(Vector2Int size)
        {
            for (int i = 0; i < _texturePool.Count; i++)
            {
                var pooled = _texturePool[i];
                if (pooled != null && pooled.width == size.x && pooled.height == size.y)
                {
                    _texturePool.RemoveAt(i);
                    return pooled;
                }
            }

            // 24-bit depth includes the stencil buffer that Mask components need.
            var texture = new RenderTexture(size.x, size.y, 24, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Default)
            {
                name = "Page Curl Capture",
                hideFlags = HideFlags.HideAndDontSave,
                filterMode = FilterMode.Bilinear,
                wrapMode = TextureWrapMode.Clamp,
                useMipMap = false
            };
            texture.Create();
            return texture;
        }

        Vector2Int CaptureSize(Rect slot)
        {
            // Match the slot's size on screen, whatever the canvas render mode.
            var canvas = GetComponentInParent<Canvas>();
            Camera eventCamera = null;
            if (canvas != null && canvas.rootCanvas.renderMode != RenderMode.ScreenSpaceOverlay)
                eventCamera = canvas.rootCanvas.worldCamera != null ? canvas.rootCanvas.worldCamera : Camera.main;

            var origin = ScreenPoint(eventCamera, slot.min);
            float width = Vector2.Distance(origin, ScreenPoint(eventCamera, new Vector2(slot.xMax, slot.yMin)));
            float height = Vector2.Distance(origin, ScreenPoint(eventCamera, new Vector2(slot.xMin, slot.yMax)));
            if (width < 1f || height < 1f)
            {
                width = slot.width;
                height = slot.height;
            }

            width *= captureScale;
            height *= captureScale;
            float maxSize = Mathf.Min(SystemInfo.maxTextureSize, 4096);
            float shrink = Mathf.Min(1f, maxSize / Mathf.Max(width, height));
            return new Vector2Int(Mathf.Max(8, Mathf.RoundToInt(width * shrink)), Mathf.Max(8, Mathf.RoundToInt(height * shrink)));
        }

        Vector2 ScreenPoint(Camera eventCamera, Vector2 localPoint) =>
            RectTransformUtility.WorldToScreenPoint(eventCamera, transform.TransformPoint(localPoint));

        RawImage CreateSlot(string slotName)
        {
            var slotObject = new GameObject(slotName, typeof(RectTransform)) { layer = gameObject.layer };
            slotObject.transform.SetParent(transform, false);
            var image = slotObject.AddComponent<RawImage>();
            image.raycastTarget = false;
            return image;
        }

        PageCurlGraphic CreateCurl()
        {
            var curlObject = new GameObject("[Page Curl] Turning Page", typeof(RectTransform)) { layer = gameObject.layer };
            curlObject.transform.SetParent(transform, false);
            var curlRect = (RectTransform)curlObject.transform;
            curlRect.anchorMin = Vector2.zero;
            curlRect.anchorMax = Vector2.one;
            curlRect.offsetMin = Vector2.zero;
            curlRect.offsetMax = Vector2.zero;
            curlRect.pivot = _rect.pivot;

            // A nested canvas keeps the per-frame mesh rebuild from re-batching the rest of the UI.
            var canvas = curlObject.AddComponent<Canvas>();
            const AdditionalCanvasShaderChannels channels = AdditionalCanvasShaderChannels.TexCoord1 | AdditionalCanvasShaderChannels.TexCoord2;
            canvas.additionalShaderChannels |= channels;
            var rootCanvas = GetComponentInParent<Canvas>();
            if (rootCanvas != null)
                rootCanvas.rootCanvas.additionalShaderChannels |= channels;

            var graphic = curlObject.AddComponent<PageCurlGraphic>();
            graphic.raycastTarget = false;
            graphic.material = _material;
            curlObject.SetActive(false);
            return graphic;
        }

        static void DestroyTexture(RenderTexture texture)
        {
            if (texture == null)
                return;
            texture.Release();
            Destroy(texture);
        }
    }
}
