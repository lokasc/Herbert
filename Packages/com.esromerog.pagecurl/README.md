# Page Curl

Physical page turning for **uGUI canvases**, in the style of Apple Books and Kindle. It works on desktop and
mobile with mouse, touch, keyboard and gamepad, through the new Input System.

- Works in every canvas render mode: Screen Space Overlay, Screen Space Camera and World Space. With a
  perspective camera the curl lifts off the page in real 3D.
- Pages can be **live UI** (TextMeshPro, Images, Buttons and so on) or plain textures. At rest, UI pages stay
  live and interactive. During a turn they are captured to a texture and drawn on the curling mesh.
- Single page (phone) or two-page spread (tablet or desktop) layouts.
- The spine can be on the Left, Right (right-to-left books), Top or Bottom. Left and Right turn with horizontal
  gestures; Top and Bottom turn with vertical ones (calendar or notepad flip).
- Drag the corner or the edge, flick, tap the page edges, or use Input System actions (arrow keys, Page Up/Down
  and gamepad shoulders by default; rebind them freely).
- Everything is tunable from the inspector.

## Quick start

1. **GameObject ▸ UI ▸ Page Curl Book** creates a book with six sample pages, and also creates a Canvas and an
   EventSystem with `InputSystemUIInputModule` if the scene doesn't have them yet.
2. Press Play. Drag from the right edge, flick, tap near the edges, or press ← / →.

To use your own pages, make each page a child RectTransform of the book and assign it to **Pages ▸ Content**.
You can also right-click the component and choose **Collect Pages From Children**. Pages without content can use
a **Texture** instead, and a page with neither is blank paper.

Requirements: the canvas needs a `GraphicRaycaster`, and the scene needs an `EventSystem` with
`InputSystemUIInputModule` for drags and taps. Keys and gamepad buttons work without them.

## Components

| Component | What it does |
|---|---|
| `PageCurlBook` | Owns the pages, the turn state machine and the curl rendering. Add it to a RectTransform inside a Canvas. |
| `PageCurlInput` | Drag, flick and tap gestures through the EventSystem, plus next/previous Input System actions. |
| `PageCurlGraphic` | Created at runtime: the mesh of the turning page. |
| `PageCurlRaycastTarget` | Invisible graphic so empty parts of the book still receive drags. Added automatically if the book has no Graphic. |

## Tuning

**Curl Shape**
- **Curl Radius**: radius of the curl, as a fraction of page width.
- **Cone Taper**: corner grabs wrap the page around a cone that widens away from the corner, giving the Apple
  Books corner curl. Grabs near the middle of the edge stay a straight cylinder (Kindle). 0 makes every grab a
  cylinder.
- **Lift Scale**: how far the curl lifts towards the camera. It's only visible with perspective cameras and is
  ignored on Overlay canvases.
- **Curl/Taper Segments**: mesh resolution.
- **Constrain To Paper**: the corner can't be pulled further than a sheet bound at the spine allows, and the
  spine never lifts.

**Paper**
- **Paper Color**: shows behind UI pages and on blank pages.
- **Back Face** (single page layout): `SeeThrough` shows the front faintly and mirrored, the way Apple Books does
  (strength set by **See Through**). `Texture` shows **Back Texture**. Spreads always show the next page.

**Lighting**
- Light direction, ambient, glossy highlight, and the colour, width and offset of the soft shadows.

**Feel**
- **Corner Freedom**: 0 keeps the fold parallel to the spine (Kindle); 1 lets the corner follow the finger
  (Apple Books).
- **Complete Threshold / Flick Speed**: when a released page finishes turning instead of falling back.
- **Drag/Release Smooth Time**: how tightly the page follows the finger and how fast it settles.
- **Auto Turn Duration / Curve / Grab / Arc**: the animated turn used for keys, taps and code.

**Capture**
- **Capture Scale**: resolution of captured UI pages relative to screen size.
- **Recapture Every Turn**: turn this off for static pages. You then call `MarkDirty(page)` when a page changes.
- **Capture Layer**: layer for the hidden capture camera (UI by default).

`PageCurlInput` options:
- Drag on/off, **Axis Bias** (how dominant the turn direction must be), and **Drag Zone** (where drags may start).
- Tap on/off and **Tap Zone**.
- **Next/Previous Page Action**: either embedded actions with editable bindings, or references to actions in your
  `.inputactions` asset.

## Scripting

```csharp
book.NextPage();            // animated; queued if a turn is already playing
book.PreviousPage();
book.GoToPage(4);           // instant jump
book.MarkDirty(2);          // recapture a UI page that changed
book.SetPages(newPages);

book.onPageChanged.AddListener(page => Debug.Log($"Now on page {page}"));
book.onTurnProgress.AddListener(t => audio.pitch = 1f + t * 0.2f);

// Drive a turn from your own input (points in the book's local space):
book.BeginDrag(localPoint, direction: +1);
book.Drag(localPoint);
book.EndDrag(localVelocityPerSecond);
```

## How it works

Apple Books and Kindle use private renderers, so the effect is rebuilt from published reverse-engineering:

- **Cone deformation.** Hong, Card and Chen, *Turning Pages of 3D Electronic Books* (3DUI 2006), model a turning
  page as paper wrapped around a cone. This is the technique credited for the iBooks corner curl, and it's
  described in Microsoft's Project Austin write-up.
- **Cylinder deformation.** XBPageCurl (iOS) and harism's android_page_curl wrap the page around a cylinder and
  keep the page's corner under the finger.

This plugin wraps the page around a cylinder for grabs near the middle of the edge, and around a cone for corner
grabs, blending between the two the way Project Austin does. For each frame:

1. The finger becomes a dragged corner in page space, where x runs from the spine to the free edge.
   - It's constrained so the paper can't stretch: the corner stays within reach of both spine ends.
   - The fold may only tilt as far as the paper has been pulled, so the grabbed point is always the most
     curled-up part of the page.
2. The curl axis is placed analytically so the grabbed point lands exactly under the finger. This solves
   `r (a − sin a) = d` while it's still on the cylinder.
   - The radius shrinks as the page approaches fully turned, so it lands flat.
   - The radius also shrinks if a tighter curl would lift the spine.
3. The page is cut into strips parallel to the axis and emitted **back to front**, since canvases draw without
   a depth buffer:
   - the shadow cast on the next page;
   - the flat part of the page;
   - the soft shadow of the folded flap;
   - the curl strips, in the order they roll up;
   - the flap.
4. Lighting (Lambert plus a highlight, relative to a flat page) is computed per vertex. A small UI shader picks
   the front or back texture and blends the see-through paper. It's based on `UI/Default`, so RectMask2D and
   stencil Masks still work.

During development the geometry was checked against these properties over thousands of random drags: no
stretch, the grab point stays under the finger, the spine never lifts, a fully turned page lands flat and
mirrored, and the curl changes continuously.

## Notes and limitations

- The turning page is a separate nested Canvas, so rebuilding its mesh every frame doesn't re-batch the rest of
  your UI.
- A captured UI page shows the page as it was when the turn started. Animated content freezes until the turn
  ends.
- The book adds a `CanvasGroup` to each UI page to hide it during turns. Pages that aren't visible are
  deactivated.
- With **Recapture Every Turn** on (the default), each turn renders up to four captures. That's cheap for typical
  pages. Turn it off for heavy pages and use `MarkDirty`.
