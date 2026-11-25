import { Story } from "inkjs";
import type {
  Choice,
  InkValue,
  Line,
  Mode,
  Phase,
  Snapshot,
  Speaker,
  Toast,
} from "./types";

/**
 * Tag conventions used by the ink files (see header of ChartAndInterview.ink):
 *   #nursenotification  line is the nurse's feedback
 *   #system_message     small notification ("You discovered ...")
 *   #empathyscore       debug line ("Current empathy: N") — never shown to the player
 *   #angry / #happy     Herbert's emotion
 *   #repeat_question    Herbert is annoyed the same topic was asked again
 */
const SPEAKER_RE = /^(Player|Herbert|Nurse):\s*/;

/** One compiled ink story plus the "run until the next choice" loop. */
class StoryRunner {
  readonly story: Story;
  constructor(
    json: string,
    onSwitchState: (state: string) => void,
  ) {
    this.story = new Story(json);
    this.story.BindExternalFunction("switchState", (state: string) => {
      onSwitchState(state);
    });
  }

  /**
   * Continue the story until it needs a choice (or ends), classifying each
   * output line. This is the web equivalent of Unity's AdvanceStoryLine loop.
   */
  pump(nextLineId: () => number) {
    const lines: Line[] = [];
    const system: string[] = [];
    let nurse: Line | null = null;

    while (this.story.canContinue) {
      const raw = this.story.Continue() ?? "";
      const tags = this.story.currentTags ?? [];
      const text = raw.trim();
      if (!text) continue;
      if (tags.includes("empathyscore")) continue;
      if (tags.includes("system_message")) {
        system.push(text);
        continue;
      }
      const line = parseLine(text, tags, nextLineId());
      if (line.speaker === "nurse") nurse = line;
      else lines.push(line);
    }

    const choices: Choice[] = this.story.currentChoices.map((c) => ({
      index: c.index,
      text: c.text,
      tags: c.tags ?? [],
    }));
    const ended = choices.length === 0 && !this.story.canContinue;
    return { lines, system, nurse, choices, ended };
  }

  goTo(path: string) {
    this.story.ChoosePathString(path);
  }

  getVar(name: string): InkValue {
    try {
      const v = this.story.variablesState[name];
      return (v as InkValue) ?? null;
    } catch {
      return null;
    }
  }

  setVar(name: string, value: InkValue) {
    this.story.variablesState[name] = value as never;
  }

  allVars(): Record<string, InkValue> {
    const out: Record<string, InkValue> = {};
    // inkjs has no public way to enumerate globals; the Map is stable API-wise.
    const globals = (
      this.story.variablesState as unknown as {
        _globalVariables?: Map<string, unknown>;
      }
    )._globalVariables;
    for (const name of globals?.keys() ?? []) out[name] = this.getVar(name);
    return out;
  }

  visited(knot: string): boolean {
    try {
      return (this.story.state?.VisitCountAtPathString(knot) ?? 0) > 0;
    } catch {
      return false;
    }
  }
}

function parseLine(text: string, tags: string[], id: number): Line {
  let speaker: Speaker = "narrator";
  let body = text;
  const m = SPEAKER_RE.exec(text);
  if (m) {
    speaker = m[1].toLowerCase() as Speaker;
    body = text.slice(m[0].length);
  }
  if (tags.includes("nursenotification")) speaker = "nurse";
  return {
    id,
    speaker,
    text: body,
    tags,
    emotion: tags.includes("angry")
      ? "angry"
      : tags.includes("happy")
        ? "happy"
        : undefined,
    repeat: tags.includes("repeat_question"),
  };
}

export interface StoryJson {
  main: string;
  exam: string;
}

/** Knots whose visit count we expose to the UI (chart + exam findings). */
const TRACKED_KNOTS = [
  "Full_Name",
  "Prescribed_Medications",
  "Age_Node",
  "Blood_Pressure",
  "Auscultation_Node",
  "Oxygen_Levels",
  "Visit_History",
  "ScalyPlaques_Question",
  "Abdomen_Question",
  "S3Gallop_Question",
  "JVD_Question",
  "Clubbing_Question",
  "BibasilarCrackles_Question",
];

export class GameEngine {
  private main!: StoryRunner;
  private exam: StoryRunner | null = null;
  private examJson: string;
  private mainJson: string;

  private lineCounter = 0;
  private toastCounter = 0;
  private beatCounter = 0;
  private pendingMode: Mode | null = null;
  private listeners = new Set<() => void>();
  private snap!: Snapshot;

  // mutable display state
  private mode: Mode = "interview";
  private phase: Phase = "main";
  private lines: Line[] = [];
  private cursor = 0;
  private choices: Choice[] = [];
  private nurse: Line | null = null;
  private toasts: Toast[] = [];
  private ended = false;
  private examStarted = false;

  constructor(json: StoryJson) {
    this.mainJson = json.main;
    this.examJson = json.exam;
    this.reset();
  }

  // ---------- external store plumbing ----------
  subscribe = (fn: () => void) => {
    this.listeners.add(fn);
    return () => this.listeners.delete(fn);
  };
  getSnapshot = () => this.snap;

  private emit() {
    this.snap = this.buildSnapshot();
    this.listeners.forEach((l) => l());
  }

  private get active(): StoryRunner {
    return this.phase === "exam" && this.exam ? this.exam : this.main;
  }

  private buildSnapshot(): Snapshot {
    const vars = this.active.allVars();
    const visited: Record<string, boolean> = {};
    for (const k of TRACKED_KNOTS) {
      const runner = this.exam && k.match(/Question$/) ? this.exam : this.main;
      visited[k] = runner.visited(k);
    }
    const empathy = Number(this.active.getVar("empathy") ?? 0);
    return {
      ready: true,
      mode: this.mode,
      phase: this.phase,
      beatId: this.beatCounter,
      lines: this.lines,
      cursor: this.cursor,
      choices: this.choices,
      nurse: this.nurse,
      toasts: this.toasts,
      empathy,
      vars,
      visited,
      ended: this.ended,
      examStarted: this.examStarted,
    };
  }

  // ---------- lifecycle ----------
  reset() {
    this.lineCounter = 0;
    this.beatCounter = 0;
    this.pendingMode = null;
    this.mode = "interview";
    this.phase = "main";
    this.lines = [];
    this.cursor = 0;
    this.choices = [];
    this.nurse = null;
    this.toasts = [];
    this.ended = false;
    this.examStarted = false;
    this.exam = null;
    this.main = new StoryRunner(this.mainJson, (s) => this.onSwitch(s));
    this.runBeat();
    this.emit();
  }

  private onSwitch(state: string) {
    if (state === "chart" || state === "interview" || state === "base")
      this.pendingMode = state;
    else if (state === "explore") this.pendingMode = "explore";
  }

  private nextLineId = () => ++this.lineCounter;

  /** Run the active story to its next choice point and fold it into display state. */
  private runBeat() {
    const runner = this.active;
    this.pendingMode = null;
    const beat = runner.pump(this.nextLineId);
    if (this.pendingMode) this.mode = this.pendingMode;
    this.beatCounter++;

    if (beat.nurse) {
      // Nurse feedback overlays whatever card was already on screen.
      this.nurse = beat.nurse;
      if (beat.lines.length) {
        this.lines = beat.lines;
        this.cursor = Math.max(0, beat.lines.length - 1);
      }
    } else if (!beat.lines.length && beat.choices.length && this.lines.length) {
      // A knot that is nothing but choices (e.g. Diet_Question_2): keep the
      // previous line on screen so the options have context.
      this.nurse = null;
      this.cursor = Math.max(0, this.lines.length - 1);
    } else {
      this.nurse = null;
      this.lines = beat.lines;
      this.cursor = 0;
    }
    this.choices = beat.choices;
    this.ended = beat.ended;
    for (const text of beat.system)
      this.toasts = [...this.toasts, { id: ++this.toastCounter, text }];

    if (beat.ended && this.phase === "exam") {
      this.syncEmpathyBack();
      this.mode = "debrief";
    }
  }

  // ---------- player actions ----------
  /** Click on the dialogue card while more lines are queued. */
  advanceLine() {
    if (this.cursor < this.lines.length - 1) {
      this.cursor++;
      this.emit();
    }
  }

  choose(index: number) {
    if (!this.choices.some((c) => c.index === index)) return;
    this.active.story.ChooseChoiceIndex(index);
    this.runBeat();
    this.emit();
  }

  dismissNurse() {
    if (!this.nurse) return;
    this.nurse = null;
    const only = this.choices.length === 1 ? this.choices[0] : null;
    if (only && only.text.trim().toLowerCase() === "continue") {
      this.active.story.ChooseChoiceIndex(only.index);
      this.runBeat();
    }
    this.emit();
  }

  dismissToast(id: number) {
    this.toasts = this.toasts.filter((t) => t.id !== id);
    this.emit();
  }

  /** Bottom bar: "Patient chart" (same jump Unity's StartChart does). */
  openChart() {
    this.jump("Look_at_Chart");
  }

  /** Bottom bar: "Patient interview". */
  openInterview() {
    this.jump("Ask_Patient_Questions");
  }

  private jump(path: string) {
    if (this.phase !== "main") return;
    this.main.goTo(path);
    this.runBeat();
    this.emit();
  }

  /** "Go to physical" button. */
  startPhysical() {
    if (this.phase === "exam") return;
    this.phase = "exam";
    if (!this.exam) {
      this.exam = new StoryRunner(this.examJson, (s) => this.onSwitch(s));
      this.exam.setVar("empathy", Number(this.main.getVar("empathy") ?? 0));
      this.examStarted = false;
      this.mode = "interview"; // consent question is a normal dialogue card
      this.runBeat();
    } else {
      this.exam.setVar("empathy", Number(this.main.getVar("empathy") ?? 0));
      this.exam.goTo("Physical_Exam");
      this.runBeat();
    }
    this.examStarted = true;
    this.emit();
  }

  /** Back from the exam to the bedside menu. */
  leaveExam() {
    if (this.phase !== "exam") return;
    this.syncEmpathyBack();
    this.phase = "main";
    this.mode = "base";
    this.nurse = null;
    this.lines = [];
    this.choices = [];
    this.emit();
  }

  /** Click on a body hotspot: jump straight to its knot (like StartChart does). */
  examine(knot: string) {
    if (this.phase !== "exam" || !this.exam || this.mode !== "explore") return;
    this.mode = "interview";
    this.exam.goTo(knot);
    // Examination dialogue never calls switchState, so it stays in dialogue
    // mode until the hub knot (Physical_Exam) switches back to "explore".
    this.runBeat();
    this.emit();
  }

  endExam() {
    if (this.phase !== "exam" || !this.exam) return;
    this.mode = "interview";
    this.exam.goTo("End_Exam");
    this.runBeat();
    this.emit();
  }

  private syncEmpathyBack() {
    if (this.exam)
      this.main.setVar("empathy", Number(this.exam.getVar("empathy") ?? 0));
  }
}
