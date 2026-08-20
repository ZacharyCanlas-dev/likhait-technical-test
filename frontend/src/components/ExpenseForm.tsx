/**
 * Form component for adding/editing expenses
 */

import React from "react";
import { ExpenseFormData } from "../types";
import { EXPENSE_CATEGORIES } from "../constants/categories";
import { TextField, SelectBox, Button } from "../vibes";
import { COLORS } from "../constants/colors";
import { useExpenseForm } from "../hooks/useExpenseForm";
import { today } from "../utils/expenseUtils";

interface ExpenseFormProps {
  initialData?: Partial<ExpenseFormData>;
  onSubmit: (data: ExpenseFormData) => Promise<void>;
  onCancel?: () => void;
  submitLabel?: string;
}

export function ExpenseForm({
  initialData,
  onSubmit,
  onCancel,
  submitLabel = "Add Expense",
}: ExpenseFormProps) {
  const {
    formData,
    errors,
    submitError,
    isSubmitting,
    handleChange,
    handleSubmit,
  } = useExpenseForm({
    initialData,
    onSubmit,
  });

  const formStyle: React.CSSProperties = {
    display: "flex",
    flexDirection: "column",
    gap: "1rem",
  };

  const buttonGroupStyle: React.CSSProperties = {
    display: "flex",
    gap: "0.5rem",
    marginTop: "0.5rem",
  };

  const submitErrorStyle: React.CSSProperties = {
    padding: "0.75rem",
    borderRadius: "0.375rem",
    border: `1px solid ${COLORS.red.re04}`,
    backgroundColor: COLORS.red.re02,
    color: COLORS.red.re07,
    fontSize: "0.875rem",
  };

  const categoryOptions = EXPENSE_CATEGORIES.map((category) => ({
    value: category,
    label: category,
  }));

  return (
    <form onSubmit={handleSubmit} style={formStyle} noValidate>
      <TextField
        label="Amount"
        type="number"
        step="0.01"
        placeholder="0.00"
        value={formData.amount}
        onChange={(e) => handleChange("amount", e.target.value)}
        error={errors.amount}
        fullWidth
        required
      />

      <TextField
        label="Description"
        type="text"
        placeholder="Enter description"
        value={formData.description}
        onChange={(e) => handleChange("description", e.target.value)}
        error={errors.description}
        fullWidth
        required
      />

      <SelectBox
        label="Category"
        options={categoryOptions}
        value={formData.category}
        onChange={(e) => handleChange("category", e.target.value)}
        error={errors.category}
        fullWidth
        required
      />

      <TextField
        label="Date"
        type="date"
        max={today()}
        value={formData.date}
        onChange={(e) => handleChange("date", e.target.value)}
        error={errors.date}
        fullWidth
        required
      />

      {submitError && (
        <div style={submitErrorStyle} role="alert">
          {submitError}
        </div>
      )}

      <div style={buttonGroupStyle}>
        <Button
          type="submit"
          variant="primary"
          disabled={isSubmitting}
          fullWidth
        >
          {isSubmitting ? "Submitting..." : submitLabel}
        </Button>
        {onCancel && (
          <Button
            type="button"
            variant="secondary"
            onClick={onCancel}
            disabled={isSubmitting}
          >
            Cancel
          </Button>
        )}
      </div>
    </form>
  );
}
