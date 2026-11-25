"use client";

import { useEffect, useState } from "react";
import { useGame } from "./GameContext";
import { HOTSPOTS } from "@/lib/game/content";
import { RIG } from "@/lib/game/rig.generated";

const A = "/assets/herbert";

/**
 * Herbert, assembled from the separate Unity sprite parts (torso, head, arms,
 * face features). The Unity version is a rigged 2D-animation skeleton; here
 * the pose is static and the "animation" is CSS: breathing, blinking, mouth
 * movement while he talks, and a small reaction to #angry / #happy lines.
 */
export function Patient() {
  const { snap, speaking, engine } = useGame();
  const line = snap.lines[snap.cursor];
  const emotion = line?.speaker === "herbert" ? line.emotion : undefined;
  const exploring = snap.mode === "explore";

  // blink: eye1 -> eye4 (closed) -> eye1, every few seconds
  const [blink, setBlink] = useState(false);
  useEffect(() => {
    let t: ReturnType<typeof setTimeout>;
    const loop = () => {
      t = setTimeout(
        () => {
          setBlink(true);
          t = setTimeout(() => {
            setBlink(false);
            loop();
          }, 130);
        },
        2200 + Math.random() * 2800,
      );
    };
    loop();
    return () => clearTimeout(t);
  }, []);

  // mouth flaps while speaking
  const [flap, setFlap] = useState(false);
  useEffect(() => {
    if (!speaking) return;
    const i = setInterval(() => setFlap((f) => !f), 140);
    return () => {
      clearInterval(i);
      setFlap(false);
    };
  }, [speaking]);

  const eye = blink ? 4 : emotion === "angry" ? 3 : 1;

  const box = (b: { left: number; top: number; width: number; rot: number }) => ({
    left: `${b.left}%`,
    top: `${b.top}%`,
    width: `${b.width}%`,
    rotate: `${b.rot}deg`,
  });

  return (
    <div
      className="patient"
      data-emotion={emotion ?? ""}
      style={{ aspectRatio: `${RIG.aspect[0]} / ${RIG.aspect[1]}` }}
    >
      <div className="patient__breathe">
        {/* torso, legs, arms, plaques, neck: one flattened layer from the Unity rig */}
        <img className="patient__body" src={`${A}/body.webp`} alt="Herbert" draggable={false} />

        <div className="patient__head" style={box(RIG.head)}>
          <img src={`${A}/head.webp`} alt="" draggable={false} />
          <img className="patient__face" style={box(RIG.eyes)} src={`${A}/eye${eye}.webp`} alt="" draggable={false} />
          <img className="patient__face" style={box(RIG.nose)} src={`${A}/nose.webp`} alt="" draggable={false} />
          <img
            className="patient__face"
            style={box(RIG.mouth)}
            src={`${A}/mouth${flap ? 2 : 1}.webp`}
            alt=""
            draggable={false}
          />
        </div>

        {exploring &&
          HOTSPOTS.map((h) => {
            const found = snap.visited[h.knot];
            return (
              <button
                key={h.id}
                type="button"
                aria-label={h.label}
                className={`hotspot ${found ? "is-found" : ""}`}
                style={{
                  left: `${h.x - h.w}%`,
                  top: `${h.y - h.h}%`,
                  width: `${h.w * 2}%`,
                  height: `${h.h * 2}%`,
                }}
                onClick={() => engine.examine(h.knot)}
              >
                <span className="hotspot__label">{h.label}</span>
              </button>
            );
          })}
      </div>
    </div>
  );
}
