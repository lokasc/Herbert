using UnityEngine;

// Put this on a GameObject that also has a Collider2D (for sprites) or a Collider (for 3D objects).
public class SymptomHitbox : MonoBehaviour
{
    [SerializeField] private SymptomSO symptom;

    public SymptomSO Symptom => symptom;
}
