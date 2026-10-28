using UnityEditor;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.InputSystem.UI;
using UnityEngine.UI;

namespace PageCurl.Editor
{
    static class PageCurlMenu
    {
        static readonly Color[] SampleColors =
        {
            new(0.98f, 0.97f, 0.94f),
            new(0.93f, 0.96f, 0.98f),
            new(0.97f, 0.93f, 0.93f),
            new(0.93f, 0.97f, 0.93f),
            new(0.97f, 0.96f, 0.90f),
            new(0.95f, 0.93f, 0.98f)
        };

        [MenuItem("GameObject/UI/Page Curl Book", false, 2100)]
        static void CreateBook(MenuCommand command)
        {
            var parent = command.context as GameObject;
            var canvas = parent != null ? parent.GetComponentInParent<Canvas>() : Object.FindFirstObjectByType<Canvas>();
            if (canvas == null)
                canvas = CreateCanvas();
            EnsureEventSystem();

            var bookParent = parent != null && parent.transform is RectTransform ? parent.transform : canvas.transform;
            var bookObject = new GameObject("Page Curl Book", typeof(RectTransform));
            GameObjectUtility.SetParentAndAlign(bookObject, bookParent.gameObject);
            var bookRect = (RectTransform)bookObject.transform;
            bookRect.sizeDelta = new Vector2(600f, 800f);

            bookObject.AddComponent<PageCurlRaycastTarget>();
            var book = bookObject.AddComponent<PageCurlBook>();
            bookObject.AddComponent<PageCurlInput>();

            var font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            var serializedBook = new SerializedObject(book);
            var pagesProperty = serializedBook.FindProperty("pages");
            pagesProperty.arraySize = SampleColors.Length;
            for (int i = 0; i < SampleColors.Length; i++)
            {
                var page = CreateSamplePage(bookRect, i, SampleColors[i], font);
                pagesProperty.GetArrayElementAtIndex(i).FindPropertyRelative("content").objectReferenceValue = page;
            }
            serializedBook.ApplyModifiedPropertiesWithoutUndo();

            Undo.RegisterCreatedObjectUndo(bookObject, "Create Page Curl Book");
            Selection.activeGameObject = bookObject;
        }

        static RectTransform CreateSamplePage(RectTransform book, int index, Color color, Font font)
        {
            var pageObject = new GameObject($"Page {index + 1}", typeof(RectTransform), typeof(Image));
            var page = (RectTransform)pageObject.transform;
            page.SetParent(book, false);
            page.anchorMin = Vector2.zero;
            page.anchorMax = Vector2.one;
            page.offsetMin = Vector2.zero;
            page.offsetMax = Vector2.zero;
            pageObject.GetComponent<Image>().color = color;

            AddText(page, "Title", $"Chapter {index + 1}", 56, FontStyle.Bold, new Vector2(0.1f, 0.78f), new Vector2(0.9f, 0.92f), font);
            AddText(page, "Body",
                "Drag from the edge to turn the page, or flick it. Tap near the edges or use the arrow keys for an automatic turn.\n\n" +
                "Grab near a corner and move along the spine to curl the corner like a real sheet of paper.",
                28, FontStyle.Normal, new Vector2(0.1f, 0.2f), new Vector2(0.9f, 0.74f), font);
            AddText(page, "Folio", (index + 1).ToString(), 24, FontStyle.Normal, new Vector2(0.4f, 0.04f), new Vector2(0.6f, 0.1f), font);
            return page;
        }

        static void AddText(RectTransform parent, string objectName, string content, int size, FontStyle style, Vector2 anchorMin, Vector2 anchorMax, Font font)
        {
            var textObject = new GameObject(objectName, typeof(RectTransform), typeof(Text));
            var rect = (RectTransform)textObject.transform;
            rect.SetParent(parent, false);
            rect.anchorMin = anchorMin;
            rect.anchorMax = anchorMax;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;

            var text = textObject.GetComponent<Text>();
            text.font = font;
            text.text = content;
            text.fontSize = size;
            text.fontStyle = style;
            text.alignment = objectName == "Body" ? TextAnchor.UpperLeft : TextAnchor.MiddleCenter;
            text.color = new Color(0.15f, 0.15f, 0.18f);
            text.raycastTarget = false;
        }

        static Canvas CreateCanvas()
        {
            var canvasObject = new GameObject("Canvas", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            canvasObject.layer = LayerMask.NameToLayer("UI");
            var canvas = canvasObject.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            var scaler = canvasObject.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1080f, 1920f);
            scaler.matchWidthOrHeight = 0.5f;
            Undo.RegisterCreatedObjectUndo(canvasObject, "Create Canvas");
            return canvas;
        }

        static void EnsureEventSystem()
        {
            if (Object.FindFirstObjectByType<EventSystem>() != null)
                return;
            var eventSystem = new GameObject("EventSystem", typeof(EventSystem), typeof(InputSystemUIInputModule));
            Undo.RegisterCreatedObjectUndo(eventSystem, "Create EventSystem");
        }
    }
}
