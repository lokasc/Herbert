using System;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.InputSystem;
using UnityEngine.UI;

namespace PageCurl
{
    /// <summary>
    /// Turns the pages of a <see cref="PageCurlBook"/> by dragging (mouse or touch through the EventSystem),
    /// tapping near an edge, or Input System actions such as the arrow keys.
    /// The gesture axis follows the book's spine: Left/Right spines swipe horizontally, Top/Bottom vertically.
    /// Needs an EventSystem with an InputSystemUIInputModule and a GraphicRaycaster on the canvas.
    /// </summary>
    [RequireComponent(typeof(PageCurlBook))]
    [AddComponentMenu("UI/Page Curl/Page Curl Input")]
    public class PageCurlInput : MonoBehaviour, IBeginDragHandler, IDragHandler, IEndDragHandler, IPointerClickHandler
    {
        [Header("Drag")]
        [SerializeField] bool dragToTurn = true;
        [Tooltip("A drag must move this many times further along the turn axis than across it to start a turn.")]
        [SerializeField, Range(0f, 4f)] float axisBias = 1f;
        [Tooltip("Fraction of the page, measured from the edge a turn starts at, where drags may begin. 1 allows anywhere.")]
        [SerializeField, Range(0.05f, 1f)] float dragZone = 1f;

        [Header("Tap")]
        [SerializeField] bool tapToTurn = true;
        [Tooltip("Fraction of the page at each end that turns on tap: the free edge goes forward, the spine side back.")]
        [SerializeField, Range(0f, 0.5f)] float tapZone = 0.25f;

        [Header("Actions")]
        [Tooltip("Turns forward when performed. Use an action from an .inputactions asset, or edit the bindings here.")]
        [SerializeField] InputActionProperty nextPageAction = new(CreateAction("Next Page",
            "<Keyboard>/rightArrow", "<Keyboard>/downArrow", "<Keyboard>/pageDown", "<Gamepad>/rightShoulder", "<Gamepad>/dpad/right"));
        [Tooltip("Turns backward when performed.")]
        [SerializeField] InputActionProperty previousPageAction = new(CreateAction("Previous Page",
            "<Keyboard>/leftArrow", "<Keyboard>/upArrow", "<Keyboard>/pageUp", "<Gamepad>/leftShoulder", "<Gamepad>/dpad/left"));

        PageCurlBook _book;
        RectTransform _rect;
        bool _dragging;
        int _pointerId;
        Vector2 _lastPoint;
        float _lastTime;
        Vector2 _velocity;

        void Awake()
        {
            _book = GetComponent<PageCurlBook>();
            _rect = (RectTransform)transform;
            // The book needs a raycast target of its own so empty parts of a page still receive drags.
            if (!TryGetComponent<Graphic>(out _))
                gameObject.AddComponent<PageCurlRaycastTarget>();
        }

        void OnEnable()
        {
            Subscribe(nextPageAction, OnNextPage);
            Subscribe(previousPageAction, OnPreviousPage);
        }

        void OnDisable()
        {
            Unsubscribe(nextPageAction, OnNextPage);
            Unsubscribe(previousPageAction, OnPreviousPage);
            if (_dragging)
            {
                _dragging = false;
                _book.EndDrag(Vector2.zero);
            }
        }

        public void OnBeginDrag(PointerEventData eventData)
        {
            if (!dragToTurn || _dragging || eventData.button != PointerEventData.InputButton.Left)
                return;
            if (!TryGetLocal(eventData.pressPosition, eventData.pressEventCamera, out var press) ||
                !TryGetLocal(eventData.position, eventData.pressEventCamera, out var current))
                return;

            var frame = _book.Frame;
            var delta = frame.DirectionFromBook(current - press);
            if (Mathf.Abs(delta.x) <= Mathf.Abs(delta.y) * axisBias)
                return;

            // Pulling towards the spine turns forward; pushing away from it brings the previous page back.
            int direction = delta.x < 0f ? 1 : -1;
            if (!InDragZone(frame.FromBook(press), direction))
                return;

            // Start from the press point so the movement before the drag threshold isn't lost.
            if (!_book.BeginDrag(press, direction))
                return;

            _dragging = true;
            _pointerId = eventData.pointerId;
            _velocity = Vector2.zero;
            _lastPoint = current;
            _lastTime = Time.unscaledTime;
            _book.Drag(current);
        }

        public void OnDrag(PointerEventData eventData)
        {
            if (!_dragging || eventData.pointerId != _pointerId)
                return;
            if (!TryGetLocal(eventData.position, eventData.pressEventCamera, out var current))
                return;

            float now = Time.unscaledTime;
            float elapsed = now - _lastTime;
            if (elapsed > 1e-4f)
                _velocity = Vector2.Lerp(_velocity, (current - _lastPoint) / elapsed, 0.6f);
            _lastPoint = current;
            _lastTime = now;
            _book.Drag(current);
        }

        public void OnEndDrag(PointerEventData eventData)
        {
            if (!_dragging || eventData.pointerId != _pointerId)
                return;

            _dragging = false;
            // A finger that stopped before lifting shouldn't flick.
            if (Time.unscaledTime - _lastTime > 0.1f)
                _velocity = Vector2.zero;
            _book.EndDrag(_velocity);
        }

        public void OnPointerClick(PointerEventData eventData)
        {
            if (!tapToTurn || eventData.dragging || _book.IsTurning || eventData.button != PointerEventData.InputButton.Left)
                return;
            if (!TryGetLocal(eventData.position, eventData.pressEventCamera, out var local))
                return;

            var frame = _book.Frame;
            var point = frame.FromBook(local);
            float width = frame.Width;
            bool backZone = _book.Layout == BookLayout.TwoPageSpread
                ? point.x <= -width * (1f - tapZone)
                : point.x <= width * tapZone;

            if (point.x >= width * (1f - tapZone))
                _book.NextPage();
            else if (backZone)
                _book.PreviousPage();
        }

        bool InDragZone(Vector2 press, int direction)
        {
            float width = _book.Frame.Width;
            if (direction > 0)
                return press.x >= width * (1f - dragZone);
            // In a spread the previous page is grabbed on the facing side, past the spine.
            if (_book.Layout == BookLayout.TwoPageSpread)
                return press.x <= -width * (1f - dragZone);
            return press.x <= width * dragZone;
        }

        bool TryGetLocal(Vector2 screenPoint, Camera eventCamera, out Vector2 local) =>
            RectTransformUtility.ScreenPointToLocalPointInRectangle(_rect, screenPoint, eventCamera, out local);

        void OnNextPage(InputAction.CallbackContext context) => _book.NextPage();
        void OnPreviousPage(InputAction.CallbackContext context) => _book.PreviousPage();

        static void Subscribe(InputActionProperty property, Action<InputAction.CallbackContext> callback)
        {
            var action = property.action;
            if (action == null)
                return;
            action.performed += callback;
            action.Enable();
        }

        static void Unsubscribe(InputActionProperty property, Action<InputAction.CallbackContext> callback)
        {
            var action = property.action;
            if (action == null)
                return;
            action.performed -= callback;
            // Actions from an asset may be shared with other systems; only disable our own embedded ones.
            if (property.reference == null)
                action.Disable();
        }

        static InputAction CreateAction(string actionName, params string[] bindings)
        {
            var action = new InputAction(actionName, InputActionType.Button);
            foreach (var binding in bindings)
                action.AddBinding(binding);
            return action;
        }
    }
}
