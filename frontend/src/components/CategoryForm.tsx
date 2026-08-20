/**
 * Form component for creating expense categories
 */

import React, { useRef, useState } from "react";
import { Category } from "../types";
import { ApiError } from "../services/api";
import { CATEGORY_ICON_CHOICES } from "../constants/categoryIcons";
import { COLORS } from "../constants/colors";
import {
  CATEGORY_NAME_MAX_LENGTH,
  foldCategoryName,
} from "../utils/categoryName";
import { TextField, Button } from "../vibes";
import { CategoryAvatar } from "./CategoryAvatar";
import { CategoryList } from "./CategoryList";
import { IconPicker } from "./IconPicker";

interface SubmitError {
  scope: "name" | "request";
  message: string;
}

interface CategoryFormProps {
  categories: Category[];
  isLoading: boolean;
  loadError: string | null;
  onSubmit: (name: string, icon: string | null) => Promise<Category>;
  onDone: () => void;
}

export function CategoryForm({
  categories,
  isLoading,
  loadError,
  onSubmit,
  onDone,
}: CategoryFormProps) {
  const [name, setName] = useState("");
  const [icon, setIcon] = useState<string | null>(null);
  const [submitError, setSubmitError] = useState<SubmitError>();
  const [createdName, setCreatedName] = useState<string>();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const nameInput = useRef<HTMLInputElement>(null);

  const trimmedName = name.trim();
  const foldedName = foldCategoryName(trimmedName);

  const existingCategory = categories.find(
    (category) => foldCategoryName(category.name) === foldedName,
  );

  // The name doubles as a filter, so a name already taken is answered by the
  // list rather than by a rejected submission.
  const matchingCategories = trimmedName
    ? categories.filter((category) =>
        foldCategoryName(category.name).includes(foldedName),
      )
    : categories;

  const canSubmit = Boolean(trimmedName) && !existingCategory && !isSubmitting;

  const handleChange = (value: string) => {
    setName(value);
    setSubmitError(undefined);
    setCreatedName(undefined);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!canSubmit) return;

    setIsSubmitting(true);
    try {
      const category = await onSubmit(trimmedName, icon);
      setName("");
      setIcon(null);
      setSubmitError(undefined);
      setCreatedName(category.name);
      nameInput.current?.focus();
    } catch (err) {
      setSubmitError(
        err instanceof ApiError && err.status === 422
          ? { scope: "name", message: err.message }
          : {
              scope: "request",
              message: "The category could not be saved. Try again.",
            },
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  const charactersLeft = CATEGORY_NAME_MAX_LENGTH - name.length;

  const helperText = existingCategory
    ? {
        text: `"${existingCategory.name}" already exists.`,
        color: COLORS.orange.or07,
      }
    : charactersLeft <= 20
      ? {
          text: `${charactersLeft} characters left.`,
          color: COLORS.text.secondary,
        }
      : undefined;

  const formStyle: React.CSSProperties = {
    display: "flex",
    flexDirection: "column",
    gap: "1rem",
  };

  // Reserved rather than conditional, here and in the live region below, so the
  // controls do not jump when a message appears or clears.
  const helperStyle: React.CSSProperties = {
    minHeight: "1rem",
    marginTop: "-0.75rem",
    fontSize: "0.75rem",
    color: helperText?.color,
  };

  const fieldLabelStyle: React.CSSProperties = {
    display: "block",
    marginBottom: "0.5rem",
    fontSize: "0.875rem",
    fontWeight: 600,
    color: COLORS.text.primary,
  };

  const liveRegionStyle: React.CSSProperties = {
    minHeight: "1.25rem",
    fontSize: "0.8125rem",
    color: COLORS.green.gr07,
  };

  const alertStyle: React.CSSProperties = {
    padding: "0.5rem 0.75rem",
    borderRadius: "0.375rem",
    border: `1px solid ${COLORS.red.re04}`,
    backgroundColor: COLORS.red.re02,
    color: COLORS.red.re07,
    fontSize: "0.8125rem",
  };

  const buttonGroupStyle: React.CSSProperties = {
    display: "flex",
    gap: "0.5rem",
    justifyContent: "flex-end",
    marginTop: "0.5rem",
  };

  return (
    <form onSubmit={handleSubmit} style={formStyle}>
      <TextField
        ref={nameInput}
        label="Category name"
        type="text"
        placeholder="e.g. Groceries"
        value={name}
        onChange={(e) => handleChange(e.target.value)}
        error={submitError?.scope === "name" ? submitError.message : undefined}
        maxLength={CATEGORY_NAME_MAX_LENGTH}
        autoFocus
        fullWidth
      />
      <span style={helperStyle}>{helperText?.text}</span>

      <div>
        <span style={fieldLabelStyle}>Icon (optional)</span>
        <IconPicker
          choices={CATEGORY_ICON_CHOICES}
          value={icon}
          onChange={setIcon}
          label="Icon"
          fallback={
            <CategoryAvatar name={trimmedName || "?"} icon={null} size={20} />
          }
          fallbackLabel="No icon, use the first letter of the name"
        />
      </div>

      {submitError?.scope === "request" && (
        <div style={alertStyle} role="alert">
          {submitError.message}
        </div>
      )}

      <div style={liveRegionStyle} aria-live="polite">
        {createdName &&
          `"${createdName}" added. ${categories.length} categories.`}
      </div>

      <div>
        <span style={fieldLabelStyle}>
          {trimmedName
            ? `Categories (${matchingCategories.length} of ${categories.length} shown)`
            : `Categories (${categories.length})`}
        </span>
        <CategoryList
          categories={categories}
          matching={matchingCategories}
          isLoading={isLoading}
          loadError={loadError}
          createdName={createdName}
          duplicateId={existingCategory?.id}
        />
      </div>

      <div style={buttonGroupStyle}>
        <Button type="button" variant="secondary" onClick={onDone}>
          Close
        </Button>
        <Button type="submit" variant="primary" disabled={!canSubmit}>
          {isSubmitting ? "Adding..." : "Add Category"}
        </Button>
      </div>
    </form>
  );
}
