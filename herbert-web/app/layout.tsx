import type { Metadata, Viewport } from "next";
import { Caveat, Source_Serif_4 } from "next/font/google";
import "./globals.css";

const serif = Source_Serif_4({
  variable: "--font-serif",
  subsets: ["latin"],
  display: "swap",
});
const hand = Caveat({
  variable: "--font-hand",
  subsets: ["latin"],
  display: "swap",
});

export const metadata: Metadata = {
  title: "Herbert — a heart failure assessment",
  description:
    "A visual-novel training game that teaches nurses to assess a patient with heart failure.",
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  themeColor: "#e9e2d0",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${serif.variable} ${hand.variable}`}>
      <body>{children}</body>
    </html>
  );
}
