"use client";

import { useCallback, useEffect, useRef, useState } from "react";

export interface PanZoom {
  x: number;
  y: number;
  z: number;
}

const MIN_Z = 1;
const MAX_Z = 3.5;
const IDLE: PanZoom = { x: 0, y: 0, z: 1 };

/**
 * Pan + zoom for the physical exam, the web version of GameManager's free
 * camera: wheel / pinch zoom, drag / one-finger pan, WASD / arrow keys.
 * The transformed layer must use `transform-origin: 0 0`.
 */
export function usePanZoom(
  ref: React.RefObject<HTMLElement | null>,
  enabled: boolean,
) {
  const [pz, setPz] = useState<PanZoom>(IDLE);
  const [dragging, setDragging] = useState(false);
  const moved = useRef(false);
  const pointers = useRef(new Map<number, { x: number; y: number }>());
  const lastPinch = useRef(0);

  const clamp = useCallback(
    (next: PanZoom): PanZoom => {
      const el = ref.current;
      if (!el) return next;
      const { width, height } = el.getBoundingClientRect();
      const z = Math.min(MAX_Z, Math.max(MIN_Z, next.z));
      return {
        z,
        x: Math.min(0, Math.max(width - width * z, next.x)),
        y: Math.min(0, Math.max(height - height * z, next.y)),
      };
    },
    [ref],
  );

  const zoomAt = useCallback(
    (factor: number, cx: number, cy: number) => {
      setPz((p) => {
        const z = Math.min(MAX_Z, Math.max(MIN_Z, p.z * factor));
        const k = z / p.z;
        return clamp({ z, x: cx - (cx - p.x) * k, y: cy - (cy - p.y) * k });
      });
    },
    [clamp],
  );

  useEffect(() => {
    const el = ref.current;
    if (!el || !enabled) return;

    const local = (e: { clientX: number; clientY: number }) => {
      const r = el.getBoundingClientRect();
      return { x: e.clientX - r.left, y: e.clientY - r.top };
    };

    const onWheel = (e: WheelEvent) => {
      e.preventDefault();
      const { x, y } = local(e);
      zoomAt(Math.exp(-e.deltaY * 0.0015), x, y);
    };

    const onDown = (e: PointerEvent) => {
      pointers.current.set(e.pointerId, { x: e.clientX, y: e.clientY });
      moved.current = false;
      lastPinch.current = 0;
    };

    const onMove = (e: PointerEvent) => {
      const prev = pointers.current.get(e.pointerId);
      if (!prev) return;
      const cur = { x: e.clientX, y: e.clientY };
      pointers.current.set(e.pointerId, cur);

      if (pointers.current.size >= 2) {
        const [a, b] = [...pointers.current.values()];
        const dist = Math.hypot(a.x - b.x, a.y - b.y);
        if (lastPinch.current > 0) {
          const mid = local({ clientX: (a.x + b.x) / 2, clientY: (a.y + b.y) / 2 });
          zoomAt(dist / lastPinch.current, mid.x, mid.y);
        }
        lastPinch.current = dist;
        moved.current = true;
        return;
      }

      const dx = cur.x - prev.x;
      const dy = cur.y - prev.y;
      if (!moved.current && Math.hypot(dx, dy) < 3) return;
      moved.current = true;
      setDragging(true);
      setPz((p) => clamp({ ...p, x: p.x + dx, y: p.y + dy }));
    };

    const onUp = (e: PointerEvent) => {
      pointers.current.delete(e.pointerId);
      lastPinch.current = 0;
      if (pointers.current.size === 0) setDragging(false);
    };

    // A drag must not also count as a click on a hotspot.
    const onClickCapture = (e: MouseEvent) => {
      if (moved.current) {
        e.stopPropagation();
        e.preventDefault();
        moved.current = false;
      }
    };

    const onKey = (e: KeyboardEvent) => {
      const step = 60;
      const { width, height } = el.getBoundingClientRect();
      switch (e.key) {
        case "a":
        case "ArrowLeft":
          setPz((p) => clamp({ ...p, x: p.x + step }));
          break;
        case "d":
        case "ArrowRight":
          setPz((p) => clamp({ ...p, x: p.x - step }));
          break;
        case "w":
        case "ArrowUp":
          setPz((p) => clamp({ ...p, y: p.y + step }));
          break;
        case "s":
        case "ArrowDown":
          setPz((p) => clamp({ ...p, y: p.y - step }));
          break;
        case "+":
        case "=":
          zoomAt(1.25, width / 2, height / 2);
          break;
        case "-":
          zoomAt(0.8, width / 2, height / 2);
          break;
      }
    };

    el.addEventListener("wheel", onWheel, { passive: false });
    el.addEventListener("pointerdown", onDown);
    el.addEventListener("pointermove", onMove);
    window.addEventListener("pointerup", onUp);
    window.addEventListener("pointercancel", onUp);
    el.addEventListener("click", onClickCapture, true);
    window.addEventListener("keydown", onKey);
    return () => {
      el.removeEventListener("wheel", onWheel);
      el.removeEventListener("pointerdown", onDown);
      el.removeEventListener("pointermove", onMove);
      window.removeEventListener("pointerup", onUp);
      window.removeEventListener("pointercancel", onUp);
      el.removeEventListener("click", onClickCapture, true);
      window.removeEventListener("keydown", onKey);
      setPz(IDLE); // leaving the exam camera resets it
    };
  }, [enabled, ref, zoomAt, clamp]);

  const zoomBy = useCallback(
    (factor: number) => {
      const el = ref.current;
      if (!el) return;
      const { width, height } = el.getBoundingClientRect();
      zoomAt(factor, width / 2, height / 2);
    },
    [ref, zoomAt],
  );

  const reset = useCallback(() => setPz(IDLE), []);

  return { pz, dragging, zoomBy, reset };
}
