/**
 * Elements that can receive focus
 */
const focusableElements = [
  'a[href]:not([tabindex^="-"])',
  'area[href]:not([tabindex^="-"])',
  'input:not([type="hidden"]):not([type="radio"]):not([disabled]):not([tabindex^="-"])',
  'input[type="radio"]:not([disabled]):not([tabindex^="-"])',
  'select:not([disabled]):not([tabindex^="-"])',
  'textarea:not([disabled]):not([tabindex^="-"])',
  'button:not([disabled]):not([tabindex^="-"])',
  'iframe:not([tabindex^="-"])',
  'audio[controls]:not([tabindex^="-"])',
  'video[controls]:not([tabindex^="-"])',
  '[contenteditable]:not([tabindex^="-"])',
  '[tabindex]:not([tabindex^="-"]):not(.cdk-focus-trap-anchor)',
];

/**
 * Find all focusable element within a given container
 */
export function findAllFocusableElementsWithin(container:HTMLElement):NodeListOf<Element> {
  return container.querySelectorAll(focusableElements.toString());
}
