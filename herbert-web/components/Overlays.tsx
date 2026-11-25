"use client";

import { useEffect, useRef, useState } from "react";
import { useGame } from "./GameContext";
import { Marker } from "./Marker";
import { HOTSPOTS, nurseMood } from "@/lib/game/content";

/** Nurse feedback: portrait + speech card; tap to dismiss. */
export function NurseCard() {
  const { engine, snap } = useGame();
  const n = snap.nurse;
  if (!n) return null;
  const mood = nurseMood(n.text);
  return (
    <button
      type="button"
      className={`nurse nurse--${mood}`}
      onClick={() => engine.dismissNurse()}
      key={n.id}
    >
      <span className="nurse__portrait">
        <img src={`/assets/nurse/${mood}.webp`} alt="" draggable={false} />
      </span>
      <span className="nurse__bubble">
        <span className="nurse__who">Nurse</span>
        <span className="nurse__text">{n.text}</span>
        <span className="nurse__hint">tap to continue</span>
      </span>
    </button>
  );
}

/**
 * "Are you sure?" before the one-way trip to the physical exam, asked by the
 * nurse (same portrait + bubble as her feedback) with highlightable answers.
 */
export function NurseConfirm() {
  const { engine, snap } = useGame();
  if (!snap.confirmPhysical) return null;
  return (
    <div className="nurse nurse--confirm" role="alertdialog" aria-label="Go to the physical examination?">
      <span className="nurse__portrait">
        <img src="/assets/nurse/default.webp" alt="" draggable={false} />
      </span>
      <span className="nurse__bubble">
        <span className="nurse__who">Nurse</span>
        <span className="nurse__text">
          Going to the physical examination will end the patient interview and you won&rsquo;t be able
          to go back. Are you sure?
        </span>
        <ul className="choices choices--confirm">
          <li className="choices__item choices__item--option">
            <Marker onClick={() => engine.confirmPhysical()}>Yes, start the physical exam</Marker>
          </li>
          <li className="choices__item choices__item--back">
            <Marker onClick={() => engine.cancelPhysical()}>Not yet</Marker>
          </li>
        </ul>
      </span>
    </div>
  );
}

function ToastItem({ id, text }: { id: number; text: string }) {
  const { engine } = useGame();
  useEffect(() => {
    const t = setTimeout(() => engine.dismissToast(id), 6500);
    return () => clearTimeout(t);
  }, [id, engine]);
  return (
    <li className="toast" onClick={() => engine.dismissToast(id)}>
      <span className="toast__dot" aria-hidden />
      {text}
    </li>
  );
}

/** #system_message lines ("You discovered …") */
export function Toasts() {
  const { snap } = useGame();
  return (
    <ul className="toasts" aria-live="polite">
      {snap.toasts.map((t) => (
        <ToastItem key={t.id} id={t.id} text={t.text} />
      ))}
    </ul>
  );
}

/** Bedside menu: Patient interview (tag) + Patient chart (paper), and "Go to physical". */
export function BottomBar() {
  const { engine } = useGame();
  return (
    <>
      <button type="button" className="tag tag--physical" onClick={() => engine.requestPhysical()}>
        <span className="tag__face">
          <img src="/assets/ui/tag.webp" alt="" draggable={false} />
          <span className="tag__label">Physical exam ›</span>
        </span>
      </button>
      <div className="bottombar">
        <button type="button" className="tag tag--interview" onClick={() => engine.openInterview()}>
          <span className="tag__face">
            <img src="/assets/ui/tag.webp" alt="" draggable={false} />
            <span className="tag__label">Patient interview</span>
          </span>
        </button>
        <button type="button" className="chartbtn" onClick={() => engine.openChart()} aria-label="Patient chart">
          <span className="chartbtn__face">
            <img className="chartbtn__a" src="/assets/ui/chart-btn.png" alt="" draggable={false} />
            <img className="chartbtn__b" src="/assets/ui/chart-btn-hover.png" alt="" draggable={false} />
            <span className="chartbtn__label">Chart</span>
          </span>
        </button>
      </div>
    </>
  );
}

/** Tiny seeded PRNG so each sketched frame is hand-wobbly but stable across renders. */
function wobble(seed: number) {
  let t = seed * 2654435761;
  return () => {
    t = (t + 0x6d2b79f5) | 0;
    let x = Math.imul(t ^ (t >>> 15), 1 | t);
    x ^= x + Math.imul(x ^ (x >>> 7), 61 | x);
    return ((x ^ (x >>> 14)) >>> 0) / 4294967296;
  };
}

/** One pen pass around a rounded box: slightly off corners, a little overshoot where the pen lifts. */
function sketchPath(w: number, h: number, seed: number) {
  const r = wobble(seed);
  const j = (n = 2.4) => (r() - 0.5) * 2 * n;
  const m = 2.2; // margin inside the viewBox
  const c = 9; // corner radius
  const x0 = m + j(), y0 = m + j(), x1 = w - m + j(), y1 = h - m + j();
  const start = [x0 + c + j(3.4), y0 + j(1.6)];
  return [
    `M${start[0]} ${start[1]}`,
    `Q${(x0 + x1) / 2} ${y0 + j(3.2)} ${x1 - c} ${y0 + j()}`,
    `Q${x1 + j(2)} ${y0 + j()} ${x1 + j(1.6)} ${y0 + c}`,
    `Q${x1 + j(3.2)} ${(y0 + y1) / 2} ${x1 + j(1.6)} ${y1 - c}`,
    `Q${x1 + j()} ${y1 + j()} ${x1 - c} ${y1 + j(1.6)}`,
    `Q${(x0 + x1) / 2} ${y1 + j(3.2)} ${x0 + c} ${y1 + j()}`,
    `Q${x0 + j()} ${y1 + j()} ${x0 + j(1.6)} ${y1 - c}`,
    `Q${x0 + j(3.2)} ${(y0 + y1) / 2} ${x0 + j(1.6)} ${y0 + c + 2}`,
    // overshoot: the pen doesn't quite close the loop
    `Q${x0 + j()} ${y0 + j()} ${start[0] + 5} ${start[1] + j(2.6)}`,
  ].join(" ");
}

/**
 * Ink-outline button: transparent, with a hand-drawn double-stroke frame.
 * Hover sweeps the same highlighter stroke the dialogue text uses.
 * `w` is the width in cqw; the frame is drawn in 0.1cqw units so it never distorts.
 */
function SketchButton({
  w,
  seed,
  onClick,
  label,
  children,
}: {
  w: number;
  seed: number;
  onClick: () => void;
  label: string;
  children: React.ReactNode;
}) {
  const W = w * 10;
  const H = 90;
  return (
    <button
      type="button"
      className="sketchbtn"
      style={{ width: `${w}cqw` }}
      onClick={onClick}
      aria-label={label}
    >
      <span className="sketchbtn__hl" aria-hidden />
      <svg className="sketchbtn__frame" viewBox={`0 0 ${W} ${H}`} aria-hidden>
        <path d={sketchPath(W, H, seed)} />
        <path d={sketchPath(W, H, seed + 40)} className="sketchbtn__ghost" />
      </svg>
      <span className="sketchbtn__label">{children}</span>
    </button>
  );
}

/** HUD while examining: back / end, progress, zoom. */
export function ExamHud({
  zoom,
  onZoom,
  onReset,
}: {
  zoom: number;
  onZoom: (f: number) => void;
  onReset: () => void;
}) {
  const { engine, snap } = useGame();
  const found = HOTSPOTS.filter((h) => snap.visited[h.knot]).length;
  return (
    <>
      <button type="button" className="tag tag--end" onClick={() => engine.endExam()}>
        <span className="tag__face">
          <img src="/assets/ui/tag.webp" alt="" draggable={false} />
          <span className="tag__label">End exam</span>
        </span>
      </button>
      <div className="examhud">
        <p className="examhud__hint">
          Look Herbert over and tap what you notice.
          <small>Scroll or pinch to zoom, and drag or use WASD to pan</small>
        </p>
        <div className="examhud__row">
          <span className="examhud__count">
            {found} / {HOTSPOTS.length} examined
          </span>
          <span className="examhud__zoom" role="group" aria-label="Zoom">
            <SketchButton w={11} seed={3} onClick={() => onZoom(0.8)} label="Zoom out">
              <svg className="sketchbtn__glyph" viewBox="0 0 24 24" aria-hidden>
                <path d="M5.2 12.3 C9 11.6 14.5 12.5 18.8 11.8" />
              </svg>
            </SketchButton>
            <SketchButton w={17} seed={11} onClick={onReset} label="Reset zoom">
              {Math.round(zoom * 100)}%
            </SketchButton>
            <SketchButton w={11} seed={7} onClick={() => onZoom(1.25)} label="Zoom in">
              <svg className="sketchbtn__glyph" viewBox="0 0 24 24" aria-hidden>
                <path d="M5.2 12.3 C9 11.6 14.5 12.5 18.8 11.8" />
                <path d="M12.2 5.1 C11.6 9 12.5 14.6 11.9 18.9" />
              </svg>
            </SketchButton>
          </span>
        </div>
      </div>
    </>
  );
}

/** Shown when the exam ink reaches END (the web stand-in for the unbuilt MCQ / scoring phases). */
export function Debrief() {
  const { engine, snap } = useGame();
  return (
    <section className="card card--folder card--debrief">
      <div className="card__scroll">
        <h2 className="debrief__title">Examination complete</h2>
        <ul className="debrief__list">
          {HOTSPOTS.map((h) => (
            <li key={h.id} className={snap.visited[h.knot] ? "is-done" : ""}>
              <span aria-hidden>{snap.visited[h.knot] ? "✓" : "○"}</span> {h.label}
              {!snap.visited[h.knot] && <em> — not examined</em>}
            </li>
          ))}
        </ul>
        <p className="debrief__score">
          Empathy score <strong>{snap.empathy}</strong>
        </p>
        <ul className="choices">
          <li className="choices__item choices__item--option">
            <Marker onClick={() => engine.reset()}>Start over</Marker>
          </li>
        </ul>
      </div>
    </section>
  );
}

/** Looping music; browsers need a first gesture before audio can start. */
export function SoundToggle() {
  const ref = useRef<HTMLAudioElement | null>(null);
  const [muted, setMuted] = useState(true);

  useEffect(() => {
    const saved = localStorage.getItem("herbert-muted");
    const want = saved === "0"; // music is opt-in; remember the choice
    const start = () => {
      if (!want || !ref.current) return;
      ref.current.volume = 0.3;
      ref.current.play().then(() => setMuted(false)).catch(() => {});
    };
    if (!want) return;
    window.addEventListener("pointerdown", start, { once: true });
    return () => window.removeEventListener("pointerdown", start);
  }, []);

  const toggle = () => {
    const a = ref.current;
    if (!a) return;
    if (muted) {
      a.volume = 0.3;
      a.play().then(() => {
        setMuted(false);
        localStorage.setItem("herbert-muted", "0");
      });
    } else {
      a.pause();
      setMuted(true);
      localStorage.setItem("herbert-muted", "1");
    }
  };

  return (
    <>
      <audio ref={ref} src="/assets/audio/heart-song.mp3" loop preload="none" />
      <button type="button" className="soundbtn" onClick={toggle} aria-label={muted ? "Play music" : "Mute music"}>
        <svg viewBox="0 0 24 24" aria-hidden>
          <path className="soundbtn__note" d="M9.5 17.6V5.4l8.4-1.9v11.4" />
          <ellipse className="soundbtn__head" cx="7.3" cy="17.8" rx="2.9" ry="2.3" />
          <ellipse className="soundbtn__head" cx="15.7" cy="15.4" rx="2.9" ry="2.3" />
          {muted && <path className="soundbtn__slash" d="M4.2 4.6 C9 9.5 15.5 16 19.8 20.2" />}
        </svg>
      </button>
    </>
  );
}

/** Backtick toggles: live view of every ink variable (the team's debug window). */
export function DebugPanel() {
  const { engine, snap } = useGame();
  return (
    <aside className="debug">
      <header>
        <b>ink debug</b> · {snap.phase}/{snap.mode}
        <button type="button" onClick={() => engine.reset()}>restart</button>
      </header>
      <dl>
        {Object.entries(snap.vars).map(([k, v]) => (
          <div key={k} className={v === true ? "is-true" : ""}>
            <dt>{k}</dt>
            <dd>{String(v)}</dd>
          </div>
        ))}
      </dl>
    </aside>
  );
}
