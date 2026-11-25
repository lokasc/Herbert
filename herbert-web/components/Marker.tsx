"use client";

import { useEffect, useRef, useState } from "react";

/**
 * A text button that behaves like a highlighter pen: hover sweeps a marker
 * stroke behind the words; press deepens the stroke and shrinks the text a
 * touch, then fires `onClick` after a short beat so the selection reads.
 */
export function Marker({
  children,
  onClick,
  className = "",
  title,
  delay = 240,
}: {
  children: React.ReactNode;
  onClick: () => void;
  className?: string;
  title?: string;
  delay?: number;
}) {
  const [pressed, setPressed] = useState(false);
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(
    () => () => {
      if (timer.current) clearTimeout(timer.current);
    },
    [],
  );

  return (
    <button
      type="button"
      title={title}
      className={`marker ${pressed ? "is-pressed" : ""} ${className}`}
      onClick={() => {
        if (pressed) return;
        setPressed(true);
        timer.current = setTimeout(() => {
          setPressed(false);
          onClick();
        }, delay);
      }}
    >
      <span className="marker__text">{children}</span>
    </button>
  );
}
