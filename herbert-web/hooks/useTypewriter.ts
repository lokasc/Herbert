"use client";

import { useCallback, useEffect, useRef, useState } from "react";

/**
 * Reveals `text` character by character. `key` identifies the line so a new
 * line restarts the animation. Clicking can call `skip()` to finish early.
 */
export function useTypewriter(text: string, key: string | number, cps = 70) {
  const [state, setState] = useState<{ key: string | number; count: number }>({
    key,
    count: 0,
  });
  const skippedFor = useRef<string | number | null>(null);

  const count = state.key === key ? state.count : 0;

  useEffect(() => {
    const reduced =
      typeof window !== "undefined" &&
      window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduced || cps <= 0) {
      const id = requestAnimationFrame(() =>
        setState({ key, count: text.length }),
      );
      return () => cancelAnimationFrame(id);
    }
    skippedFor.current = null;
    const start = performance.now();
    let raf = 0;
    const tick = (now: number) => {
      if (skippedFor.current === key) return;
      const c = Math.min(text.length, Math.floor(((now - start) / 1000) * cps));
      setState((s) => (s.key === key && s.count === c ? s : { key, count: c }));
      if (c < text.length) raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [key, text, cps]);

  const skip = useCallback(() => {
    skippedFor.current = key;
    setState({ key, count: text.length });
  }, [key, text]);

  const done = count >= text.length;
  return { shown: text.slice(0, count), rest: text.slice(count), done, skip };
}
