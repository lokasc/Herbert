using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.InputSystem;

public class ResetGame : MonoBehaviour
{
    private void Update()
    {
        if (Keyboard.current != null &&
            Keyboard.current.ctrlKey.isPressed &&
            Keyboard.current.rKey.wasPressedThisFrame)
        {
            ResetCurrentScene();
        }
    }

    public void ResetCurrentScene()
    {
        SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex);
    }
}