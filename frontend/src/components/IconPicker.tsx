/**
 * Icon selector with a no-icon option
 */

import React from "react";
import { COLORS } from "../constants/colors";

interface IconPickerProps {
  choices: string[];
  value: string | null;
  onChange: (value: string | null) => void;
  label: string;
  fallback: React.ReactNode;
  fallbackLabel: string;
}

export function IconPicker({
  choices,
  value,
  onChange,
  label,
  fallback,
  fallbackLabel,
}: IconPickerProps) {
  const rowStyle: React.CSSProperties = {
    display: "flex",
    flexWrap: "wrap",
    gap: "0.375rem",
  };

  const buttonStyle = (isSelected: boolean): React.CSSProperties => ({
    display: "inline-flex",
    alignItems: "center",
    justifyContent: "center",
    width: "2rem",
    height: "2rem",
    padding: 0,
    fontSize: "1rem",
    lineHeight: 1,
    cursor: "pointer",
    borderRadius: "0.375rem",
    border: `1px solid ${isSelected ? COLORS.primary.p06 : COLORS.border}`,
    backgroundColor: isSelected ? COLORS.primary.p01 : COLORS.background.main,
    boxShadow: isSelected ? `inset 0 0 0 1px ${COLORS.primary.p06}` : "none",
  });

  return (
    <div style={rowStyle} role="group" aria-label={label}>
      <button
        type="button"
        style={buttonStyle(value === null)}
        onClick={() => onChange(null)}
        aria-pressed={value === null}
        aria-label={fallbackLabel}
      >
        {fallback}
      </button>
      {choices.map((choice) => (
        <button
          key={choice}
          type="button"
          style={buttonStyle(value === choice)}
          onClick={() => onChange(choice)}
          aria-pressed={value === choice}
          aria-label={`Use ${choice} as the icon`}
        >
          {choice}
        </button>
      ))}
    </div>
  );
}
