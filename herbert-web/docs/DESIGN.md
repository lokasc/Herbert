# Herbert Web — design document

A web port of the Unity visual novel *Herbert*: a training game where a nursing
student assesses a patient (Herbert Bower) with heart failure. **Ink drives the
content and scoring; the web app is a thin, replaceable skin on top of it.**

Status: first playable (v0.1). Unity project is untouched and remains the
reference. Nothing here is committed yet.

---

## 1. What the player does

| Screen | Unity equivalent | Web |
|---|---|---|
| **Intro** | `Patient_Introduction` (never shown in Unity — the scene starts in "base") | Plays first, in the interview folder. Ends with *Begin examination* |
| **Bedside ("base")** | Patient + bottom bar | Patient on the bed, tags: **Patient interview**, **Chart**, **Physical exam ›** (asks the nurse to confirm — see §4) |
| **Patient interview** | `Ask_Patient_Questions` + Herbert dialogue + choice buttons | The *Herbert* folder card, with Herbert zoomed in (1.5×) like the Unity scene. Lines reveal one at a time; choices are highlightable text |
| **Patient chart** | `Look_at_Chart` + each chart node | Clipboard. Rows are a vertical list; opening one writes its text on the sheet |
| **Nurse feedback** | `Nurse_Feedback` + NurseButton | Portrait + speech bubble over everything, tap to dismiss |
| **Physical exam** | free camera + `SymptomHitbox` colliders | Pan/zoom canvas; invisible hotspots over body parts |
| **Debrief** | `McqDebrief` / `ScoringScreen` stubs | One simple end-of-exam card (findings + empathy) — placeholder |

### Interaction language
* **Hover** — tags/chart icon grow and tilt slightly (the "make the bottom
  bigger" idea). Text choices get a **highlighter stroke** that sweeps in behind
  the words (`Marker.tsx`).
* **Select** — the stroke deepens to a stronger yellow and the text shrinks a
  touch for ~240 ms, *then* the choice fires, so the selection is visible.
* Choice flavours (derived from the ink text/tags, see `choiceKind`):
  normal `›`, **Continue** (handwritten, `▸`), **Return …** (muted, `↩`),
  `#checkchartagain` (italic, `☰`).
* Chart rows show a **✓** once that chart node has been read.
* Herbert's mouth moves while his line types; he blinks; the whole figure
  breathes; `#angry` shakes his head, `#happy` nods.
* Layout is a **9:16 portrait stage** (same as the 1080×1920 Unity scene),
  centered; everything inside is sized in `cqw` so it scales like a poster.

## 2. Architecture

```
ink/*.ink ──(scripts/build-ink.mjs, inkjs compiler)──► public/ink/*.json
                                                           │ fetch
lib/game/engine.ts   GameEngine = the "Ink wrapper"        ▼
   ├─ StoryRunner ×2   (main story, physical-exam story)
   └─ Snapshot  ──useSyncExternalStore──► components/*
```

* **`lib/game/engine.ts`** is framework-free (no React). It owns the ink
  stories and exposes an immutable `Snapshot` plus actions
  (`choose`, `advanceLine`, `openChart`, `openInterview`, `startPhysical`,
  `examine(knot)`, `endExam`, `dismissNurse`, `reset` …).
* Ink is pumped **one beat at a time** — run until the next choice — and each
  output line is classified (speaker prefix `Player:`/`Herbert:`/`Nurse:`,
  tags). This replaces Unity's click-per-`Continue()` loop; the UI then steps
  through a beat's lines locally.
* **`switchState("chart"|"interview"|"base"|"explore")`** is bound as an ink
  external function exactly like Unity; it sets the UI mode.
* Bottom-bar buttons jump with `ChoosePathString("Look_at_Chart")` /
  `("Ask_Patient_Questions")`, as `InkIntegration.StartChart/StartInterview` do.
  Exam hotspots do the same with their knot.
* **Two stories, one score.** `PhysicalExam.ink` is a separate file with its
  own `empathy`; the engine copies empathy main→exam on entry and back on
  exit so the score carries over.
* Visit counts (`Knot == 1` in ink, exam "was it examined?") need
  `countAllVisits`, which the build script turns on.

### UI modes (`snapshot.mode`)

| mode | shown | set by |
|---|---|---|
| `interview` | folder card (also intro + exam dialogue) | default, `switchState("interview")` |
| `chart` | clipboard | `switchState("chart")` |
| `base` | bottom bar | `switchState("base")` |
| `explore` | exam HUD + hotspots, pan/zoom | `switchState("explore")` (web-added, see §3) |
| `debrief` | summary card | exam story reaches `END` |

Nurse lines (`#nursenotification`) are not a mode: they overlay the current
card; dismissing auto-picks the lone `[Continue]` choice that follows.

### Files
```
app/                 layout (fonts), page, globals.css (all styling)
components/          Game (loader + stage), Patient, DialogueCard, ChartSheet,
                     Overlays (nurse, toasts, bottom bar, exam HUD, debrief,
                     sound, debug), Marker (highlighter button)
hooks/               useTypewriter, usePanZoom
lib/game/            engine, types, content (hotspots, chart rows)
ink/                 working copies of the .ink files
scripts/             build-ink, sync-ink-from-unity
public/assets/       optimized copies of the Unity art (webp) + music
```

## 3. Ink conventions the web relies on

Tags (from the header of `ChartAndInterview.ink`): `#nursenotification`,
`#system_message` (→ toast), `#empathyscore` (debug line, hidden),
`#angry` / `#happy` (Herbert reaction), `#repeat_question` (annoyed styling),
`#checkchartagain` (chart shortcut choice style).

Variables are read live from ink (debug panel, chart ✓, exam progress).
Press **`** (backtick) or open `/?debug` to see every variable and hotspot
outlines. **Ctrl+Shift+R** restarts (Unity's Ctrl+R).

### Web-only edits to `PhysicalExam.ink` (Unity file untouched)
1. Added `EXTERNAL switchState(stateName)`.
2. Added `-> Ask_Permission_Examine_Question` as the entry point (the Unity
   copy has no top-level divert, so it would fall into `Nurse_Feedback`).
3. Added `{switchState("explore")}` at the top of `Physical_Exam` — the hub
   knot now means "show the body, wait for a click".

`npm run sync-ink` overwrites `ink/` from `../Assets/Ink` — re-apply these
three lines (or move them into the Unity file so both stay identical).

### Things noticed in the ink (not changed)
* `Patient_Introduction` is never reached in Unity; the web plays it.
* `Scene1_Player_Decision` still lists "Ask Patient Questions (Scene1)" and
  "Proceed to Physical Exam (Scene2)", and `Patient_Physical` is a stub. The web
  ignores those choices in `base` mode and uses the buttons instead.
* "I notice some **scaly plaques on your side**" vs. the art: the plaque sprites
  sit on Herbert's *arm* in the Unity rig, so the hotspot is on the arm.
* Chart list items written as `- Furosemide …` compile as ink *gathers*. They
  render fine but a `#list_item` tag would be more robust.
* Typos that reach the player: `Diet_Question_Response_3` nurse line ends in
  ``questions``.``; `Other_Symptoms_Question` first choice has an unmatched `"`.
* `Drinking_Question_Response_3` (orange juice…) is unreachable — option 3
  points at `Response_1`.
* `Auscultation_Node` is marked "to be removed if physical can account for this".

## 4. Physical exam

`lib/game/content.ts → HOTSPOTS` maps six ellipses (percent of the patient
box) to ink knots: neck→JVD, chest→S3 gallop, lungs→crackles,
abdomen→swelling, arm→scaly plaques, hand→clubbing. Hotspots are invisible
until hovered (label + glow); examined ones get a green ring. Wheel/pinch zoom
(1–3.5×), drag/one-finger pan, WASD/arrows, +/−. A drag never counts as a
click. Flow: consent question → body → click part → dialogue + nurse feedback →
back to body → **End exam** (→ `End_Exam` → debrief).

**The physical exam is one-way.** Tapping *Physical exam ›* makes the nurse ask,
in the same portrait + bubble as her feedback: "Going to the physical
examination will end the patient interview and you won't be able to go back. Are
you sure?" — *Yes, start the physical exam* / *Not yet*. The nurse overlay is
modal (the dimmed scene is not clickable). After *Yes* there is no bedside
menu, chart or interview any more (`engine.requestPhysical → confirmPhysical`);
the only exits are **End exam** and, from the debrief, **Start over**.
The zoom controls are cardboard tags to match the rest of the UI.

## 5. Art status / known gaps

* Unity's Herbert is a rigged 2D-animation skeleton. `scripts/herbert-rig/export.py`
  reads `Assets/Scenes/Herbert.prefab`, composes every sprite's world transform
  from the bone hierarchy (rest pose) and flattens the **body** (torso, legs,
  arms, scaly plaques, neck sprite) into `public/assets/herbert/body.webp`.
  The **head and face parts stay separate** so CSS can blink, flap the mouth and
  react to `#angry`/`#happy`; their placement is generated into
  `lib/game/rig.generated.ts`. Re-run it (`python3 -I herbert-web/scripts/herbert-rig/export.py`,
  needs Pillow + numpy) if the prefab or art changes. This reproduces the rest
  pose only — Unity's breathing animation is approximated with a CSS scale.
* Hotspots are % of that figure box; the export prints reference points.
* Eye sprites: only `eye1` (open), `eye3` (narrowed, used for angry) and
  `eye4` (blink) are used; `eye2` is unused.
* Sprites are `webp` copies in `public/assets` (Unity originals untouched).
* `1_HeartSong.mp3` is included behind an opt-in ♪ button (browsers block
  autoplay).

## 6. Open questions

1. ~~**Desktop layout.**~~ **Decided: keep the portrait column** (faithful to
   the Unity scene, works on phones; desktop gets side margins).
2. **Should the empathy score be visible** during play, or only at the end?
   It is hidden now (the ink "Current empathy" lines are debug).
3. **Repeatable topics** (ink comment "TO ASK THE GROUP"): main topics are `*`
   (vanish) vs chart follow-ups `+` (sticky). The UI just follows ink.
4. **Exam discoverability.** Hotspots are hidden like Unity's colliders. If
   players struggle, add a "tap to reveal hints" toggle (the debug outline
   already exists).
5. **MCQ debrief + scoring** phases are still placeholders.
6. **Persistence / analytics** (save progress, send scores to an instructor)?

## 7. Running it

```bash
cd herbert-web
npm install
npm run dev        # compiles ink/*.ink first (predev), then Next on :3000
npm run ink        # recompile ink only
npm run build
```
Edit `ink/*.ink` and re-run `npm run ink` (or restart dev) — reload the page.
