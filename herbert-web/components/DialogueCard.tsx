"use client";

import { useEffect } from "react";
import { useGame } from "./GameContext";
import { Marker } from "./Marker";
import { useTypewriter } from "@/hooks/useTypewriter";
import type { Choice } from "@/lib/game/types";

export function choiceKind(c: Choice) {
  const t = c.text.trim().toLowerCase();
  if (c.tags.includes("checkchartagain")) return "chart";
  if (t === "continue") return "continue";
  if (t.startsWith("return")) return "back";
  return "option";
}

export function ChoiceList({ className = "" }: { className?: string }) {
  const { engine, snap } = useGame();
  return (
    <ul className={`choices ${className}`}>
      {snap.choices.map((c, i) => (
        <li
          key={`${snap.beatId}-${c.index}`}
          className={`choices__item choices__item--${choiceKind(c)}`}
          style={{ animationDelay: `${i * 55}ms` }}
        >
          <Marker onClick={() => engine.choose(c.index)}>{c.text}</Marker>
        </li>
      ))}
    </ul>
  );
}

/**
 * The patient-interview card (the "Herbert" folder). Lines are revealed one
 * at a time; click the text to finish typing / go to the next line. When the
 * last line has finished, the ink choices appear as highlightable text.
 */
export function DialogueCard() {
  const { engine, snap, setSpeaking } = useGame();
  const line = snap.lines[snap.cursor];
  const { shown, rest, done, skip } = useTypewriter(line?.text ?? "", line?.id ?? 0);
  const isLast = snap.cursor >= snap.lines.length - 1;
  const showChoices = isLast && done && snap.choices.length > 0 && !snap.nurse;
  const canAdvance = done && !isLast;

  useEffect(() => {
    setSpeaking(line?.speaker === "herbert" && !done && !snap.nurse);
    return () => setSpeaking(false);
  }, [line?.speaker, done, snap.nurse, setSpeaking]);

  const onTextClick = () => {
    if (!done) skip();
    else if (!isLast) engine.advanceLine();
  };

  return (
    <section className="card card--folder" aria-live="polite">
      <div className="card__scroll">
        {line && (
          <button
            type="button"
            className={`line line--${line.speaker} ${line.repeat ? "line--annoyed" : ""}`}
            onClick={onTextClick}
            disabled={done && isLast}
            key={line.id}
          >
            {line.speaker !== "narrator" && (
              <span className="line__who">
                {line.speaker === "herbert" ? "Herbert" : "You"}
              </span>
            )}
            <span className="line__text">
              {shown}
              <span className="line__ghost">{rest}</span>
            </span>
            {canAdvance && <span className="line__more" aria-hidden>▾</span>}
          </button>
        )}
        {showChoices && <ChoiceList />}
      </div>
    </section>
  );
}
