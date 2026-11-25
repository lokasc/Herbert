/**
 * Web-side content config that connects ink knots to UI. Everything the
 * player *reads* lives in ink; this file only says where to click.
 */

/** Chart rows: choice text in Look_at_Chart -> knot that marks it as reviewed. */
export const CHART_ROW_KNOT: Record<string, string> = {
  "Full Name": "Full_Name",
  "Prescribed Medications": "Prescribed_Medications",
  Age: "Age_Node",
  "Blood Pressure": "Blood_Pressure",
  "Auscultation Results": "Auscultation_Node",
  "Oxygen Levels": "Oxygen_Levels",
  "Medical Visit History": "Visit_History",
};

export interface Hotspot {
  id: string;
  /** ink knot jumped to on click (same trick Unity's StartChart uses) */
  knot: string;
  /** shown on hover + in the debrief */
  label: string;
  /** ellipse in patient-local % (center x/y, radius w/h) */
  x: number;
  y: number;
  w: number;
  h: number;
}

/**
 * Click targets for the physical exam — the web stand-in for Unity's
 * SymptomHitbox colliders. Coordinates are % of the figure box (the flattened body
 * image from scripts/herbert-rig), so they follow the figure. Tweak freely.
 */
export const HOTSPOTS: Hotspot[] = [
  { id: "jvd", knot: "JVD_Question", label: "Neck", x: 40, y: 22, w: 6, h: 2.6 },
  { id: "s3", knot: "S3Gallop_Question", label: "Chest", x: 52, y: 35, w: 8, h: 3.4 },
  { id: "crackles", knot: "BibasilarCrackles_Question", label: "Lungs", x: 27, y: 40, w: 8, h: 3.6 },
  { id: "abdomen", knot: "Abdomen_Question", label: "Abdomen", x: 44, y: 49, w: 10, h: 3.8 },
  { id: "plaques", knot: "ScalyPlaques_Question", label: "Arm", x: 15, y: 49, w: 6, h: 4.2 },
  { id: "clubbing", knot: "Clubbing_Question", label: "Hand", x: 58, y: 62, w: 6, h: 2.8 },
  // Second lung: same knot as "crackles" (bibasilar = both lung bases).
  { id: "crackles-r", knot: "BibasilarCrackles_Question", label: "Lungs", x: 61, y: 42.5, w: 7, h: 3.4 },
  { id: "legs", knot: "Feet_Question", label: "Legs", x: 51, y: 85, w: 8, h: 4.5 },
];

/** One entry per finding: several hotspots can open the same knot but count once. */
export const EXAM_FINDINGS: Hotspot[] = HOTSPOTS.filter(
  (h, i) => HOTSPOTS.findIndex((o) => o.knot === h.knot) === i,
);

export function nurseMood(text: string): "happy" | "upset" {
  return /^(good|great) job/i.test(text.trim()) ? "happy" : "upset";
}
