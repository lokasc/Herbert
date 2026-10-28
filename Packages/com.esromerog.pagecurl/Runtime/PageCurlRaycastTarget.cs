using UnityEngine;
using UnityEngine.UI;

namespace PageCurl
{
    /// <summary>Invisible graphic that lets the whole book rect receive pointer events without drawing anything.</summary>
    [AddComponentMenu("UI/Page Curl/Page Curl Raycast Target")]
    [RequireComponent(typeof(CanvasRenderer))]
    public class PageCurlRaycastTarget : Graphic
    {
        public override void SetMaterialDirty() { }
        public override void SetVerticesDirty() { }

        protected override void OnPopulateMesh(VertexHelper vh) => vh.Clear();
    }
}
