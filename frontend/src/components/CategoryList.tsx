/**
 * Scrollable list of existing categories, filtered as a name is typed
 */

import React, { useEffect, useRef } from "react";
import { Category } from "../types";
import { COLORS } from "../constants/colors";
import { CategoryAvatar } from "./CategoryAvatar";

interface CategoryListProps {
  categories: Category[];
  matching: Category[];
  isLoading: boolean;
  loadError: string | null;
  createdName?: string;
  duplicateId?: number;
}

export function CategoryList({
  categories,
  matching,
  isLoading,
  loadError,
  createdName,
  duplicateId,
}: CategoryListProps) {
  const createdChip = useRef<HTMLLIElement>(null);

  // A new category lands in alphabetical position, which may be outside the
  // scrolled region that is meant to confirm it was created.
  useEffect(() => {
    if (createdName) {
      createdChip.current?.scrollIntoView({ block: "nearest" });
    }
  }, [createdName]);

  const listStyle: React.CSSProperties = {
    display: "flex",
    flexWrap: "wrap",
    gap: "0.5rem",
    margin: 0,
    padding: "0.25rem",
    listStyle: "none",
    maxHeight: "10rem",
    overflowY: "auto",
  };

  const chipStyle = (tone: "new" | "match" | "plain"): React.CSSProperties => ({
    display: "inline-flex",
    alignItems: "center",
    gap: "0.375rem",
    padding: "0.25rem 0.625rem",
    borderRadius: "999px",
    fontSize: "0.8125rem",
    color: COLORS.text.primary,
    border: `1px solid ${
      {
        new: COLORS.green.gr04,
        match: COLORS.orange.or04,
        plain: COLORS.border,
      }[tone]
    }`,
    backgroundColor: {
      new: COLORS.green.gr02,
      match: COLORS.orange.or02,
      plain: COLORS.background.card,
    }[tone],
  });

  const messageStyle: React.CSSProperties = {
    fontSize: "0.8125rem",
    color: COLORS.text.secondary,
  };

  if (loadError) {
    return <span style={messageStyle}>{loadError}</span>;
  }

  if (isLoading) {
    return <span style={messageStyle}>Loading categories...</span>;
  }

  if (categories.length === 0) {
    return (
      <span style={messageStyle}>
        No categories yet. An expense needs one, so start here.
      </span>
    );
  }

  if (matching.length === 0) {
    return <span style={messageStyle}>No match — this name is new.</span>;
  }

  return (
    <ul
      style={listStyle}
      tabIndex={0}
      role="list"
      aria-label="Existing categories"
    >
      {matching.map((category) => {
        const isNew = category.name === createdName;
        return (
          <li
            key={category.id}
            ref={isNew ? createdChip : undefined}
            style={chipStyle(
              isNew ? "new" : category.id === duplicateId ? "match" : "plain",
            )}
          >
            <CategoryAvatar
              name={category.name}
              icon={category.icon}
              size={16}
            />
            {category.name}
          </li>
        );
      })}
    </ul>
  );
}
