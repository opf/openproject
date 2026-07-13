/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 *
 */

import { Controller } from '@hotwired/stimulus';
import { renderStreamMessage } from '@hotwired/turbo';

// Module-level store for cursor offsets, keyed by the field's stable key.
// This survives Turbo Stream DOM replacement, while still being scoped per field.
const cursorOffsets = new Map<string, number>();

export default class extends Controller {
  static values = {
    url: String,
    dialogUrl: String,
  };

  declare urlValue:string;
  declare dialogUrlValue:string;
  declare hasDialogUrlValue:boolean;

  private boundFormDataHandler:((e:FormDataEvent) => void) | null = null;

  connect() {
    const form = this.element.closest('form');
    if (form) {
      this.boundFormDataHandler = (e:FormDataEvent) => this.appendStableKeySystemArguments(e);
      form.addEventListener('formdata', this.boundFormDataHandler);
    }

    if (this.element instanceof HTMLInputElement || this.element instanceof HTMLTextAreaElement) {
      this.setCursorPosition(this.element);
    }
  }

  disconnect() {
    const form = this.element.closest('form');
    if (form && this.boundFormDataHandler) {
      form.removeEventListener('formdata', this.boundFormDataHandler);
      this.boundFormDataHandler = null;
    }
  }

  async request(e:Event):Promise<void> {
    // Don't trigger edit mode if the user is selecting text or just finished a selection
    if (window.getSelection()?.toString()) {
      return;
    }

    // Don't trigger edit mode if clicking on a link
    const target = e.target as HTMLElement;
    if (target.tagName === 'a' || target.closest('a')) {
      return;
    }

    this.storeCursorPositionData(e);

    const response = await fetch(this.urlValue, {
      method: 'GET',
      headers: { Accept: 'text/vnd.turbo-stream.html' },
      credentials: 'same-origin',
    });

    if (response.ok) {
      renderStreamMessage(await response.text());
    } else {
      throw new Error(response.statusText);
    }
  }

  openDialog(event:Event) {
    // Don't trigger edit mode if the user is selecting text or just finished a selection
    if (window.getSelection()?.toString()) {
      return;
    }

    const target = event.target as HTMLElement;

    // Check if the event is on an interactive element that should be ignored
    if (this.isInteractiveElement(target)) {
      // Don't handle this event, let the child element handle it
      return;
    }

    // Prevent default and dispatch custom event for async-dialog to handle
    event.preventDefault();
    this.dispatch('open-dialog', { detail: { url: this.dialogUrlValue } });
  }

  submitForm() {
    const form = this.element.closest('form');
    if (form) {
      form.requestSubmit();
    }
  }

  private appendStableKeySystemArguments(e:FormDataEvent):void {
    const result:Record<string, unknown> = {};
    document.querySelectorAll<HTMLElement>('[data-inplace-edit-stable-key][data-inplace-edit-system-arguments]').forEach((el) => {
      const key = el.dataset.inplaceEditStableKey;
      const raw = el.dataset.inplaceEditSystemArguments;
      if (key && raw) {
        try {
          result[key] = JSON.parse(raw);
        } catch {
          // ignore malformed JSON
        }
      }
    });
    e.formData.set('stable_key_system_arguments', JSON.stringify(result));
  }

  private isInteractiveElement(element:HTMLElement):boolean {
    // Check if the element is or is inside an interactive element.
    let current = element;
    while (current && current !== this.element) {
      if (current.matches('button, a, dialog')) {
        return true;
      }
      current = current.parentElement!;
    }
    return false;
  }

  // When the controller is connected to a text input (i.e. the edit field has
  // just been rendered), apply the stored char offset so the cursor lands where
  // the user clicked in the display field.
  private setCursorPosition(element:HTMLInputElement|HTMLTextAreaElement):void {
    const key = this.stableKey;
    const offset = key !== undefined ? cursorOffsets.get(key) : undefined;
    if (key !== undefined) cursorOffsets.delete(key);

    if (offset !== undefined) {
      // requestAnimationFrame ensures autofocus has run and the element is focused.
      // setSelectionRange is not supported on all input types (e.g. number, date) —
      // those will silently keep the browser's default cursor placement.
      requestAnimationFrame(() => {
        try {
          element.setSelectionRange(offset, offset);
          this.scrollToCursor(element, offset);
        } catch {
          // ignore
        }
      });
    }
  }

  // setSelectionRange moves the cursor but does not update scrollLeft.
  // Approximate the cursor's pixel position proportionally via scrollWidth
  // and center it in the visible area.
  private scrollToCursor(element:HTMLInputElement|HTMLTextAreaElement, offset:number):void {
    const { scrollWidth, clientWidth, value } = element;
    if (!value.length) return;
    // Estimate the cursor's pixel position proportionally within the full text width.
    // Then shift scrollLeft so the cursor lands in the center of the visible area.
    // Math.max(0, ...) prevents a negative scroll when the cursor is near the start.
    const cursorX = (offset / value.length) * scrollWidth;
    element.scrollLeft = Math.max(0, cursorX - clientWidth / 2);
  }

  private storeCursorPositionData(e:Event):void {
    const key = this.stableKey;
    if (!key) return;

    if (e instanceof MouseEvent) {
      const container = e.currentTarget as HTMLElement;

      // For plain-text inputs: store the char offset at the click position so
      // the rendered text input can place the cursor accurately via setSelectionRange.
      let range:Range | null = null;
      // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access,@typescript-eslint/no-explicit-any
      if ((e as any).rangeParent) {
        range = document.createRange();
        // eslint-disable-next-line @typescript-eslint/no-unsafe-argument,@typescript-eslint/no-unsafe-member-access,@typescript-eslint/no-explicit-any
        range.setStart((e as any).rangeParent, (e as any).rangeOffset);
      } else {
        const legacyDocument = document as { caretRangeFromPoint?:(x:number, y:number) => Range };
        range = legacyDocument.caretRangeFromPoint?.(e.clientX, e.clientY) ?? null;
      }

      if (range && container.contains(range.startContainer)) {
        cursorOffsets.set(key, this.getCharOffset(container, range.startContainer, range.startOffset));
      } else {
        cursorOffsets.delete(key);
      }
    } else {
      cursorOffsets.delete(key);
    }
  }

  private get stableKey():string | undefined {
    return this.element.closest<HTMLElement>('[data-inplace-edit-stable-key]')?.dataset.inplaceEditStableKey;
  }

  private getCharOffset(root:Element, targetNode:Node, targetOffset:number):number {
    let count = 0;
    let node:Node|null;
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);

    while ((node = walker.nextNode())) {
      if (node === targetNode) return count + targetOffset;
      count += (node as Text).length;
    }
    return count;
  }
}
