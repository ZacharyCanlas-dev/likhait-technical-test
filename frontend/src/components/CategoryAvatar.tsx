/**
 * Category icon, or a colour-coded initial when it has none
 */

import React from "react";
import { COLORS } from "../constants/colors";

const PALETTE = [
  { background: COLORS.primary.p02, text: COLORS.primary.p10 },
  { background: COLORS.red.re02, text: COLORS.red.re10 },
  { background: COLORS.orange.or02, text: COLORS.orange.or10 },
  { background: COLORS.yellow.ye02, text: COLORS.yellow.ye10 },
  { background: COLORS.yellowGreen.yg02, text: COLORS.yellowGreen.yg10 },
  { background: COLORS.green.gr02, text: COLORS.green.gr10 },
  { background: COLORS.blueGreen.bg02, text: COLORS.blueGreen.bg10 },
];

/** Derived from the name so a category keeps its colour when the list re-sorts */
function paletteFor(name: string) {
  let hash = 0;
  for (let i = 0; i < name.length; i += 1) {
    hash = (hash * 31 + name.charCodeAt(i)) | 0;
  }
  return PALETTE[Math.abs(hash) % PALETTE.length];
}

interface CategoryAvatarProps {
  name: string;
  icon: string | null;
  size?: number;
}

export function CategoryAvatar({ name, icon, size = 20 }: CategoryAvatarProps) {
  const palette = paletteFor(name);

  const style: React.CSSProperties = {
    display: "inline-flex",
    alignItems: "center",
    justifyContent: "center",
    flexShrink: 0,
    width: `${size}px`,
    height: `${size}px`,
    borderRadius: `${Math.round(size * 0.28)}px`,
    fontSize: `${Math.round(size * (icon ? 0.78 : 0.5))}px`,
    lineHeight: 1,
    fontWeight: 700,
    backgroundColor: icon ? "transparent" : palette.background,
    color: icon ? undefined : palette.text,
  };

  return (
    <span style={style} aria-hidden="true">
      {/* First code point, not first UTF-16 unit: name[0] splits a surrogate pair. */}
      {icon || [...name][0]?.toUpperCase()}
    </span>
  );
}
