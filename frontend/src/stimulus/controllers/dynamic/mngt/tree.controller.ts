import { Controller } from '@hotwired/stimulus';

// Handles the split click behavior on sidebar tree nodes:
// - Clicking the name/avatar link: navigate to project page AND toggle expand/collapse
// - Clicking the chevron arrow: only toggle expand/collapse (native <details> behavior)
export default class MngtTreeController extends Controller<HTMLDetailsElement> {
  navigate(event: MouseEvent): void {
    event.preventDefault();

    const link = event.currentTarget as HTMLAnchorElement;

    // Toggle the <details> open state (clicking a link inside <summary> does NOT
    // trigger the native summary toggle in most browsers, so we do it manually).
    this.element.open = !this.element.open;

    window.location.href = link.href;
  }
}
