"use client";

import { useGame } from "./GameContext";
import { Marker } from "./Marker";
import { ChoiceList, choiceKind } from "./DialogueCard";
import { CHART_ROW_KNOT } from "@/lib/game/content";

const KV = /^([A-Z][A-Za-z0-9 ]{1,24}):\s+(.+)$/;

/**
 * The patient chart (clipboard). Look_at_Chart is rendered as a vertical list
 * of rows; opening a row shows that knot's text on the sheet, with the ink
 * "Return …" choices underneath.
 */
export function ChartSheet() {
  const { engine, snap } = useGame();
  const isHub = snap.choices.some((c) => c.text in CHART_ROW_KNOT);
  const rows = snap.choices.filter((c) => c.text in CHART_ROW_KNOT);
  const leave = snap.choices.filter((c) => !(c.text in CHART_ROW_KNOT));

  return (
    <section className="card card--chart">
      <div className="card__scroll">
        <h2 className="chart__title">Patient Chart</h2>

        {isHub ? (
          <>
            {snap.lines.map((l) => (
              <p key={l.id} className="chart__lede">
                {l.text}
              </p>
            ))}
            <ul className="chart__rows">
              {rows.map((c, i) => {
                const seen = snap.visited[CHART_ROW_KNOT[c.text]];
                return (
                  <li
                    key={`${snap.beatId}-${c.index}`}
                    className={`chart__row ${seen ? "is-seen" : ""}`}
                    style={{ animationDelay: `${i * 50}ms` }}
                  >
                    <span className="chart__tick" aria-hidden>
                      {seen ? "✓" : ""}
                    </span>
                    <Marker onClick={() => engine.choose(c.index)}>{c.text}</Marker>
                    <span className="chart__chev" aria-hidden>
                      ›
                    </span>
                  </li>
                );
              })}
            </ul>
            <ul className="choices choices--footer">
              {leave.map((c) => (
                <li key={c.index} className={`choices__item choices__item--${choiceKind(c)}`}>
                  <Marker onClick={() => engine.choose(c.index)}>{c.text}</Marker>
                </li>
              ))}
            </ul>
          </>
        ) : (
          <>
            <div className="chart__detail" key={snap.beatId}>
              {snap.lines.map((l) => {
                const m = KV.exec(l.text);
                return m ? (
                  <p key={l.id} className="chart__kv">
                    <span className="chart__key">{m[1]}</span>
                    <span className="chart__val">{m[2]}</span>
                  </p>
                ) : (
                  <p key={l.id} className="chart__para">
                    {l.text}
                  </p>
                );
              })}
            </div>
            <ChoiceList className="choices--footer" />
          </>
        )}
      </div>
    </section>
  );
}
