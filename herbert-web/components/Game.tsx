"use client";

import { useEffect, useRef, useState, useSyncExternalStore } from "react";
import { GameEngine } from "@/lib/game/engine";
import { GameContext } from "./GameContext";
import { Patient } from "./Patient";
import { DialogueCard } from "./DialogueCard";
import { ChartSheet } from "./ChartSheet";
import {
  BottomBar,
  Debrief,
  DebugPanel,
  ExamHud,
  NurseCard,
  NurseConfirm,
  SoundToggle,
  Toasts,
} from "./Overlays";
import { usePanZoom } from "@/hooks/usePanZoom";

/** Fetches the compiled ink, creates the engine, then renders the game. */
export function Game() {
  const [engine, setEngine] = useState<GameEngine | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    Promise.all(
      ["ChartAndInterview", "PhysicalExam"].map((n) =>
        fetch(`/ink/${n}.json`).then((r) => {
          if (!r.ok) throw new Error(`Could not load /ink/${n}.json — run "npm run ink"`);
          return r.text();
        }),
      ),
    )
      .then(([main, exam]) => {
        if (!cancelled) setEngine(new GameEngine({ main, exam }));
      })
      .catch((e) => !cancelled && setError(String(e.message ?? e)));
    return () => {
      cancelled = true;
    };
  }, []);

  if (error) return <div className="viewport"><p className="boot">{error}</p></div>;
  if (!engine) return <div className="viewport"><p className="boot">Loading chart…</p></div>;
  return <GameView engine={engine} />;
}

function GameView({ engine }: { engine: GameEngine }) {
  const snap = useSyncExternalStore(engine.subscribe, engine.getSnapshot, engine.getSnapshot);
  const [speaking, setSpeaking] = useState(false);
  // GameView only mounts client-side (after the ink fetch), so reading the URL here is safe.
  const [debug, setDebug] = useState(() => new URLSearchParams(window.location.search).has("debug"));
  const stageRef = useRef<HTMLDivElement>(null);
  const exploring = snap.mode === "explore";
  const { pz, dragging, zoomBy, reset } = usePanZoom(stageRef, exploring);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "`") setDebug((d) => !d);
      // Unity's ResetGame: Ctrl+R restarts (Shift added so browser reload still works)
      if (e.ctrlKey && e.shiftKey && e.key.toLowerCase() === "r") {
        e.preventDefault();
        engine.reset();
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [engine]);

  const worldStyle = exploring
    ? { transform: `translate(${pz.x}px, ${pz.y}px) scale(${pz.z})` }
    : undefined;

  return (
    <GameContext.Provider value={{ engine, snap, speaking, setSpeaking }}>
      <div className="viewport" data-debug={debug ? "1" : "0"}>
        <div
          ref={stageRef}
          className="stage"
          data-mode={snap.mode}
          data-nurse={snap.nurse || snap.confirmPhysical ? "1" : "0"}
          data-dragging={dragging ? "1" : "0"}
        >
          <div className="world" style={worldStyle}>
            <div className="room" />
            <Patient />
          </div>
          <div className="stage__vignette" />

          {snap.mode === "base" && <BottomBar />}
          {snap.mode === "interview" && <DialogueCard />}
          {snap.mode === "chart" && <ChartSheet />}
          {snap.mode === "explore" && <ExamHud zoom={pz.z} onZoom={zoomBy} onReset={reset} />}
          {snap.mode === "debrief" && <Debrief />}

          <NurseCard />
          <NurseConfirm />
          <Toasts />
          <SoundToggle />
          {debug && <DebugPanel />}
        </div>
      </div>
    </GameContext.Provider>
  );
}
