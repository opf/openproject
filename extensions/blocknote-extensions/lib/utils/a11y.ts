import type { KeyboardEvent as ReactKeyboardEvent, MouseEvent as ReactMouseEvent } from 'react';

export function menuButtonProps(label:string, expanded:boolean) {
  return {
    role: 'button' as const,
    'aria-label': label,
    'aria-haspopup': 'menu' as const,
    'aria-expanded': expanded,
  };
}

export type MenuButtonProps = ReturnType<typeof menuButtonProps>;

// A click the keyboard produced (Enter or Space on a button) carries no pointer detail.
export function isKeyboardClick(event?:ReactMouseEvent):boolean {
  return event?.detail === 0;
}

function getActiveElement(node:Node):Element | null {
  const root = node.getRootNode() as Document | ShadowRoot;
  return root.activeElement;
}

export function hasFocusWithin(element:Element | null):boolean {
  if (!element) return false;
  const active = getActiveElement(element);
  return active !== null && element.contains(active);
}

const MENU_ITEM_SELECTOR = '[role="menuitem"], [role="menuitemradio"]';

type MenuItemTarget = 'first' | 'last' | 'next' | 'previous' | 'checked';

// Items of nested menus belong to those menus, not to this one.
function itemsOf(menu:Element):HTMLElement[] {
  return Array.from(menu.querySelectorAll<HTMLElement>(MENU_ITEM_SELECTOR))
    .filter((item) => item.closest('[role="menu"]') === menu);
}

export function focusMenuItem(menu:Element | null, target:MenuItemTarget):void {
  if (!menu) return;
  const items = itemsOf(menu);
  if (items.length === 0) return;

  const current = items.findIndex((item) => item === getActiveElement(menu));
  const checked = items.find((item) => item.getAttribute('aria-checked') === 'true');

  const next = {
    first: items[0],
    last: items[items.length - 1],
    next: items[(current + 1) % items.length],
    previous: items[(current - 1 + items.length) % items.length],
    checked: checked ?? items[0],
  }[target];

  next.focus({ preventScroll: true });
}

const NAVIGATION_KEYS = {
  horizontal: { ArrowRight: 'next', ArrowLeft: 'previous', Home: 'first', End: 'last' },
  vertical: { ArrowDown: 'next', ArrowUp: 'previous', Home: 'first', End: 'last' },
} as const satisfies Record<string, Record<string, MenuItemTarget>>;

// Returns whether the key was one of the menu's navigation keys.
export function navigateMenu(
  event:ReactKeyboardEvent<HTMLElement>,
  orientation:keyof typeof NAVIGATION_KEYS,
):boolean {
  const keys:Partial<Record<string, MenuItemTarget>> = NAVIGATION_KEYS[orientation];
  const target = keys[event.key];
  if (!target) return false;

  event.preventDefault();
  event.stopPropagation();
  focusMenuItem(event.currentTarget, target);
  return true;
}
