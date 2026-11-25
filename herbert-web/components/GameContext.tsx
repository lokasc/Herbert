"use client";

import { createContext, useContext } from "react";
import type { GameEngine } from "@/lib/game/engine";
import type { Snapshot } from "@/lib/game/types";

export interface GameCtx {
  engine: GameEngine;
  snap: Snapshot;
  /** Herbert's mouth should move (typewriter is running on one of his lines). */
  speaking: boolean;
  setSpeaking: (v: boolean) => void;
}

export const GameContext = createContext<GameCtx | null>(null);

export function useGame() {
  const ctx = useContext(GameContext);
  if (!ctx) throw new Error("useGame must be used inside <Game>");
  return ctx;
}
