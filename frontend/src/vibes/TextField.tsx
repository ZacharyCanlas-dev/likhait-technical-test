/**
 * Reusable TextField component
 */

import React from "react";
import { COLORS } from "../constants/colors";

interface TextFieldProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  fullWidth?: boolean;
}

function TextFieldBase(
  { label, error, fullWidth = false, ...props }: TextFieldProps,
  ref: React.ForwardedRef<HTMLInputElement>,
) {
  const containerStyle: React.CSSProperties = {
    display: "flex",
    flexDirection: "column",
    gap: "0.5rem",
    width: fullWidth ? "100%" : "auto",
  };

  const labelStyle: React.CSSProperties = {
    fontSize: "0.875rem",
    fontWeight: 600,
    color: COLORS.text.primary,
  };

  const inputStyle: React.CSSProperties = {
    padding: "0.5rem 0.75rem",
    fontSize: "1rem",
    border: `1px solid ${error ? COLORS.danger : COLORS.border}`,
    borderRadius: "0.375rem",
    outline: "none",
    transition: "border-color 0.2s",
    backgroundColor: COLORS.background.main,
    color: COLORS.text.primary,
  };

  const errorStyle: React.CSSProperties = {
    fontSize: "0.75rem",
    color: COLORS.danger,
    marginTop: "-0.25rem",
  };

  return (
    <div style={containerStyle}>
      {label && <label style={labelStyle}>{label}</label>}
      <input ref={ref} style={inputStyle} {...props} />
      {error && <span style={errorStyle}>{error}</span>}
    </div>
  );
}

export const TextField = React.forwardRef(TextFieldBase);
