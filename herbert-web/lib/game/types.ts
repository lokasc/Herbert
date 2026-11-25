export type Mode =
  | "interview" // dialogue card (also used for exam dialogue + intro)
  | "chart" // clipboard
  | "base" // main menu: patient + bottom bar
  | "explore" // physical exam: pan / zoom / click body parts
  | "debrief"; // exam finished

export type Phase = "main" | "exam";

export type Speaker = "herbert" | "player" | "nurse" | "narrator";

export interface Line {
  id: number;
  speaker: Speaker;
  text: string;
  tags: string[];
  emotion?: "angry" | "happy";
  /** Herbert is annoyed because the same topic was asked again. */
  repeat?: boolean;
}

export interface Choice {
  index: number;
  text: string;
  tags: string[];
}

export interface Toast {
  id: number;
  text: string;
}

export type InkValue = string | number | boolean | null;

export interface Snapshot {
  ready: boolean;
  mode: Mode;
  phase: Phase;
  /** Increments every time ink produces a new beat; useful as a React key. */
  beatId: number;
  lines: Line[];
  /** Index into `lines` for dialogue-style display (interview). */
  cursor: number;
  choices: Choice[];
  nurse: Line | null;
  toasts: Toast[];
  empathy: number;
  /** Every global ink variable of the active story, for the debug panel + UI. */
  vars: Record<string, InkValue>;
  /** knot name -> has it been visited (exam findings). */
  visited: Record<string, boolean>;
  /** The story reached END. */
  ended: boolean;
  /** Has the player completed the consent question in the exam? */
  examStarted: boolean;
}
