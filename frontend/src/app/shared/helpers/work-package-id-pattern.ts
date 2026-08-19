/**
 * URL-safe pattern that matches work package identifiers:
 * numeric IDs ("123") and semantic identifiers ("PROJ-42").
 *
 * Used in UI Router route definitions so that both forms are accepted in URLs.
 * The backend equivalent lives in WorkPackage::SemanticIdentifier::ID_ROUTE_CONSTRAINT.
 */
export const WP_ID_URL_PATTERN = '\\d+|[A-Za-z][A-Za-z0-9_]*-\\d+';

/**
 * Detect whether a work package identifier is a semantic one (e.g. `PROJ-42`)
 * rather than a plain numeric id (e.g. `42`).
 *
 * Semantic identifiers are self-describing because they contain letters; numeric
 * ids do not. This is the canonical, mode-agnostic way for the frontend to tell
 * the two apart — there is no semantic-mode flag exposed to the client.
 *
 * @example
 * isSemanticWorkPackageId('PROJ-42') // => true
 * isSemanticWorkPackageId('42')      // => false
 * isSemanticWorkPackageId('')        // => false
 */
export function isSemanticWorkPackageId(id:string):boolean {
  return /[A-Za-z]/.test(id);
}

/**
 * Format a work package identifier for inline UI display.
 *
 * OpenProject supports two identifier modes:
 * - **Semantic**: project-scoped identifiers like `PROJ-42` that contain letters.
 *   These are self-describing and returned as-is.
 * - **Classic**: numeric-only identifiers like `42`.
 *   These are prefixed with `#` to visually distinguish them as WP references.
 *
 * @example
 * formatWorkPackageId('PROJ-42') // => 'PROJ-42'
 * formatWorkPackageId('42')      // => '#42'
 * formatWorkPackageId('')        // => ''
 */
export function formatWorkPackageId(id:string):string {
  if (!id) return '';
  return isSemanticWorkPackageId(id) ? id : `#${id}`;
}
