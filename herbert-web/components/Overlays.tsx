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
        <img src="/assets/ui/tag.webp" alt="" draggable={false} />
        <span>Physical exam ›</span>
      </button>
      <div className="bottombar">
        <button type="button" className="tag tag--interview" onClick={() => engine.openInterview()}>
          <img src="/assets/ui/tag.webp" alt="" draggable={false} />
          <span>Patient interview</span>
        </button>
        <button type="button" className="chartbtn" onClick={() => engine.openChart()} aria-label="Patient chart">
          <img className="chartbtn__a" src="/assets/ui/chart-btn.png" alt="" draggable={false} />
          <img className="chartbtn__b" src="/assets/ui/chart-btn-hover.png" alt="" draggable={false} />
          <span>Chart</span>
        </button>
      </div>
    </>
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
        <img src="/assets/ui/tag.webp" alt="" draggable={false} />
        <span>End exam</span>
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
            <button type="button" onClick={() => onZoom(0.8)} aria-label="Zoom out">−</button>
            <button type="button" onClick={onReset} aria-label="Reset zoom">{Math.round(zoom * 100)}%</button>
            <button type="button" onClick={() => onZoom(1.25)} aria-label="Zoom in">+</button>
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
        {muted ? "♪̸" : "♪"}
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
