using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.InputSystem;

// Detects taps / left clicks on SymptomHitbox objects and logs the symptom's description name.
public class SymptomHitboxDetector : MonoBehaviour
{
    [SerializeField] private Camera targetCamera;
    [SerializeField] private float maxRayDistance = 100f;

    private void Awake()
    {
        if (targetCamera == null)
        {
            targetCamera = Camera.main;
        }
    }

    private void Update()
    {
        if (targetCamera == null)
        {
            return;
        }

        if (TryGetPressPosition(out Vector2 screenPosition))
        {
            DetectHitbox(screenPosition);
        }
    }

    private bool TryGetPressPosition(out Vector2 screenPosition)
    {
        // Touch: only the first finger, on the frame it touches down.
        if (Touchscreen.current != null && Touchscreen.current.primaryTouch.press.wasPressedThisFrame)
        {
            screenPosition = Touchscreen.current.primaryTouch.position.ReadValue();
            return true;
        }

        // Mouse button 0 (left click).
        if (Mouse.current != null && Mouse.current.leftButton.wasPressedThisFrame)
        {
            screenPosition = Mouse.current.position.ReadValue();
            return true;
        }

        screenPosition = default;
        return false;
    }

    private void DetectHitbox(Vector2 screenPosition)
    {
        // Ignore presses that land on UI (buttons, dialogue panel, etc.).
        if (EventSystem.current != null && EventSystem.current.IsPointerOverGameObject())
        {
            return;
        }

        Ray ray = targetCamera.ScreenPointToRay(screenPosition);
        SymptomHitbox hitbox = null;

        // 2D colliders (sprites).
        RaycastHit2D hit2D = Physics2D.GetRayIntersection(ray, maxRayDistance);
        if (hit2D.collider != null)
        {
            hitbox = hit2D.collider.GetComponentInParent<SymptomHitbox>();
        }

        // 3D colliders.
        if (hitbox == null && Physics.Raycast(ray, out RaycastHit hit3D, maxRayDistance))
        {
            hitbox = hit3D.collider.GetComponentInParent<SymptomHitbox>();
        }

        if (hitbox == null)
        {
            return;
        }

        if (hitbox.Symptom == null)
        {
            Debug.LogWarning($"{hitbox.name} has no SymptomSO assigned.", hitbox);
            return;
        }

        Debug.Log(hitbox.Symptom.descriptionName, hitbox);
    }
}
