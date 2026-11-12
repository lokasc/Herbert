using System;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.UI;

[Serializable]
public class GameScore
{
    public int empathy = 0;
    public float gameTime = 0;
}

public class GameManager : MonoBehaviour
{
    public enum GamePhase
    {
        Interview,
        PhysicalExamination,
        McqDebrief,
        ScoringScreen
    }

    public int Empathy
    {
        get
        {
            return gameScore.empathy;
        }
        set
        {
            gameScore.empathy = value;
        }
    }

    [SerializeField] private Button physicalExaminationButton;
    [SerializeField] private GameObject InterviewDialoguePanel;
    [SerializeField] private Camera freeCamera;
    [SerializeField] private Transform panPlaneTarget;
    [SerializeField] private float cameraMoveSpeed = 5f;
    [SerializeField] private float swipeSensitivity = 0.01f;
    [SerializeField] private float zoomSensitivity = 0.001f;
    [SerializeField] private float minimumFieldOfView = 10f;
    [SerializeField] private float minimumOrthographicSize = 0.5f;

    private GameScore gameScore;

    private GameState currentState;
    private Vector3 cameraOrigin;
    private float originalFieldOfView;
    private float originalOrthographicSize;
    private float panPlaneDistance;
    private float previousPinchDistance;
    private bool freeCameraActive;

    public GamePhase CurrentPhase => currentState.Phase;

    private void Awake()
    {
        gameScore.gameTime = 0;
        gameScore.empathy = 0;
        
        if (freeCamera == null)
        {
            freeCamera = Camera.main;
        }

        if (freeCamera != null)
        {
            cameraOrigin = freeCamera.transform.position;
            originalFieldOfView = freeCamera.fieldOfView;
            originalOrthographicSize = freeCamera.orthographicSize;
            Vector3 planePoint = panPlaneTarget != null
                ? panPlaneTarget.position
                : cameraOrigin + freeCamera.transform.forward * Mathf.Max(1f, -cameraOrigin.z);
            panPlaneDistance = Mathf.Max(
                freeCamera.nearClipPlane,
                Vector3.Dot(planePoint - cameraOrigin, freeCamera.transform.forward));
        }
        else
        {
            Debug.LogError("GameManager requires a free camera or a camera tagged MainCamera.", this);
        }

        if (InterviewDialoguePanel == null)
        {
            Debug.LogError("Assign InterviewDialoguePanel on the GameManager.", this);
        }

        if (physicalExaminationButton != null)
        {
            physicalExaminationButton.onClick.AddListener(BeginPhysicalExamination);
        }
        else
        {
            Debug.LogWarning("Assign a physical examination button on the GameManager.", this);
        }

        ChangeState(GamePhase.Interview);
    }

    private void OnDestroy()
    {
        if (physicalExaminationButton != null)
        {
            physicalExaminationButton.onClick.RemoveListener(BeginPhysicalExamination);
        }
    }

    private void Update()
    {
        gameScore.gameTime += Time.deltaTime;
        if (!freeCameraActive || freeCamera == null)
        {
            return;
        }

        ReadZoomInput();

        Vector3 right = freeCamera.transform.right;
        Vector3 up = freeCamera.transform.up;
        Vector2 movement = ReadKeyboardMovement();
        Vector2 offset = GetCameraOffset(right, up);
        offset += movement * cameraMoveSpeed * Time.deltaTime;

        ReadTouchPan(ref offset);

        Vector2 maximumOffset = GetMaximumPanOffset();
        offset.x = Mathf.Clamp(offset.x, -maximumOffset.x, maximumOffset.x);
        offset.y = Mathf.Clamp(offset.y, -maximumOffset.y, maximumOffset.y);
        freeCamera.transform.position = cameraOrigin + right * offset.x + up * offset.y;
    }

    public void BeginPhysicalExamination()
    {
        if (CurrentPhase == GamePhase.Interview)
        {
            ChangeState(GamePhase.PhysicalExamination);
        }
    }

    public void ChangeState(GamePhase nextPhase)
    {
        GameState nextState = CreateState(nextPhase);
        if (currentState != null && currentState.Phase == nextPhase)
        {
            return;
        }

        currentState?.OnExitState(this);
        currentState = nextState;
        currentState.OnEnterState(this);
    }

    private static GameState CreateState(GamePhase phase)
    {
        switch (phase)
        {
            case GamePhase.Interview:
                return new InterviewState();
            case GamePhase.PhysicalExamination:
                return new PhysicalExaminationState();
            case GamePhase.McqDebrief:
                return new McqDebriefState();
            case GamePhase.ScoringScreen:
                return new ScoringScreenState();
            default:
                throw new ArgumentOutOfRangeException(nameof(phase), phase, "Unknown game phase.");
        }
    }

    private Vector2 ReadKeyboardMovement()
    {
        Keyboard keyboard = Keyboard.current;
        if (keyboard == null)
        {
            return Vector2.zero;
        }

        Vector2 movement = Vector2.zero;
        if (keyboard.aKey.isPressed) movement.x -= 1f;
        if (keyboard.dKey.isPressed) movement.x += 1f;
        if (keyboard.sKey.isPressed) movement.y -= 1f;
        if (keyboard.wKey.isPressed) movement.y += 1f;
        return movement.normalized;
    }

    private void ReadZoomInput()
    {
        if (Mouse.current != null)
        {
            float scroll = Mouse.current.scroll.ReadValue().y;
            if (!Mathf.Approximately(scroll, 0f))
            {
                ApplyZoom(Mathf.Exp(scroll * zoomSensitivity));
            }
        }

        if (Touchscreen.current == null)
        {
            previousPinchDistance = 0f;
            return;
        }

        var touches = Touchscreen.current.touches;
        bool firstPressed = touches[0].press.isPressed;
        bool secondPressed = touches[1].press.isPressed;
        if (firstPressed && secondPressed)
        {
            float pinchDistance = Vector2.Distance(
                touches[0].position.ReadValue(),
                touches[1].position.ReadValue());
            if (previousPinchDistance > 0f && pinchDistance > 0f)
            {
                ApplyZoom(pinchDistance / previousPinchDistance);
            }
            previousPinchDistance = pinchDistance;
        }
        else
        {
            previousPinchDistance = 0f;
        }
    }

    private void ReadTouchPan(ref Vector2 offset)
    {
        if (Touchscreen.current == null)
        {
            return;
        }

        var touches = Touchscreen.current.touches;
        if (!touches[0].press.isPressed || touches[1].press.isPressed)
        {
            return;
        }

        Vector2 delta = touches[0].delta.ReadValue() * swipeSensitivity;
        offset.x -= delta.x;
        offset.y -= delta.y;
    }

    private void ApplyZoom(float zoomFactor)
    {
        if (freeCamera.orthographic)
        {
            freeCamera.orthographicSize = Mathf.Clamp(
                freeCamera.orthographicSize / zoomFactor,
                Mathf.Min(minimumOrthographicSize, originalOrthographicSize),
                originalOrthographicSize);
        }
        else
        {
            freeCamera.fieldOfView = Mathf.Clamp(
                freeCamera.fieldOfView / zoomFactor,
                Mathf.Min(minimumFieldOfView, originalFieldOfView),
                originalFieldOfView);
        }
    }

    private Vector2 GetCameraOffset(Vector3 right, Vector3 up)
    {
        Vector3 displacement = freeCamera.transform.position - cameraOrigin;
        return new Vector2(Vector3.Dot(displacement, right), Vector3.Dot(displacement, up));
    }

    private Vector2 GetMaximumPanOffset()
    {
        float originalHalfHeight = freeCamera.orthographic
            ? originalOrthographicSize
            : panPlaneDistance * Mathf.Tan(originalFieldOfView * 0.5f * Mathf.Deg2Rad);
        float currentHalfHeight = freeCamera.orthographic
            ? freeCamera.orthographicSize
            : panPlaneDistance * Mathf.Tan(freeCamera.fieldOfView * 0.5f * Mathf.Deg2Rad);
        float verticalOffset = Mathf.Max(0f, originalHalfHeight - currentHalfHeight);
        float horizontalOffset = verticalOffset * freeCamera.aspect;
        return new Vector2(horizontalOffset, verticalOffset);
    }

    private abstract class GameState
    {
        public abstract GamePhase Phase { get; }
        public abstract void OnEnterState(GameManager gameManager);
        public abstract void OnExitState(GameManager gameManager);
    }

    private sealed class InterviewState : GameState
    {
        public override GamePhase Phase => GamePhase.Interview;

        public override void OnEnterState(GameManager gameManager)
        {
            if (gameManager.InterviewDialoguePanel != null)
            {
                gameManager.InterviewDialoguePanel.SetActive(true);
            }
        }

        public override void OnExitState(GameManager gameManager)
        {
            if (gameManager.InterviewDialoguePanel != null)
            {
                gameManager.InterviewDialoguePanel.SetActive(false);
            }
        }
    }

    private sealed class PhysicalExaminationState : GameState
    {
        public override GamePhase Phase => GamePhase.PhysicalExamination;

        public override void OnEnterState(GameManager gameManager)
        {
            gameManager.freeCameraActive = true;
        }

        public override void OnExitState(GameManager gameManager)
        {
            gameManager.freeCameraActive = false;
        }
    }

    private sealed class McqDebriefState : GameState
    {
        public override GamePhase Phase => GamePhase.McqDebrief;

        public override void OnEnterState(GameManager gameManager) { }
        public override void OnExitState(GameManager gameManager) { }
    }

    private sealed class ScoringScreenState : GameState
    {
        public override GamePhase Phase => GamePhase.ScoringScreen;

        public override void OnEnterState(GameManager gameManager) { }
        public override void OnExitState(GameManager gameManager) { }
    }
}
