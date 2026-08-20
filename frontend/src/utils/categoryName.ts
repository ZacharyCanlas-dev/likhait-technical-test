/**
 * Client-side mirrors of the rules Category enforces on the server
 *
 * The server stays authoritative: these let the form answer before a request is
 * made, and a rejected name still comes back as a 422.
 */

export const CATEGORY_NAME_MAX_LENGTH = 100;

/**
 * Folds case and accents, as the utf8mb4_0900_ai_ci collation behind the unique
 * index does. This approximates the collation rather than reproducing it, so a
 * name it lets through can still be rejected on save.
 */
export function foldCategoryName(name: string): string {
  return name
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "")
    .toLowerCase();
}

/** Orders names as GET /api/categories does */
export function compareCategoryNames(a: string, b: string): number {
  return foldCategoryName(a).localeCompare(foldCategoryName(b));
}
