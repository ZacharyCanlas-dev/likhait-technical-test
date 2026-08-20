/**
 * Custom hook for loading and creating expense categories
 */

import { useCallback, useEffect, useRef, useState } from "react";
import { Category } from "../types";
import { createCategory, fetchCategories } from "../services/api";
import { compareCategoryNames } from "../utils/categoryName";

export function useCategories() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const latestRequest = useRef(0);

  const loadCategories = useCallback(async () => {
    const request = (latestRequest.current += 1);
    setIsLoading(true);
    setError(null);
    try {
      const loaded = await fetchCategories();
      // A reload that started before a category was created answers without it,
      // and it replaces the whole list rather than merging into it.
      if (request !== latestRequest.current) return;
      setCategories(loaded);
    } catch (err) {
      console.error("Error fetching categories:", err);
      if (request !== latestRequest.current) return;
      setError("Categories could not be loaded.");
    } finally {
      if (request === latestRequest.current) setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    loadCategories();
  }, [loadCategories]);

  const addCategory = useCallback(
    async (name: string, icon: string | null): Promise<Category> => {
      const created = await createCategory(name, icon);
      latestRequest.current += 1;
      // Sorted because the index endpoint orders by name, and an unsorted insert
      // would leave this session's additions last until the next reload.
      setCategories((current) =>
        [...current, created].sort((a, b) =>
          compareCategoryNames(a.name, b.name),
        ),
      );
      return created;
    },
    [],
  );

  return { categories, isLoading, error, addCategory, reload: loadCategories };
}
