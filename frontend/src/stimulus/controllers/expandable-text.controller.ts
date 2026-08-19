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
 */

import { Controller } from '@hotwired/stimulus';
import { useResize } from 'stimulus-use';

// Private controller for `OpPrimer::ExpandableTextComponent`. It operates on the
// DOM that component renders — including `Primer::Beta::Truncate`'s internal
// `.Truncate-text` element for single-line measurement — and is not meant for
// standalone use.
export default class ExpandableTextController extends Controller<HTMLElement> {
  static targets = ['truncate', 'expander'];
  static values = {
    expanded: Boolean,
    mode: { type: String, default: 'single_line' },
    inline: { type: Boolean, default: true },
  };

  declare readonly truncateTarget:HTMLElement;
  declare readonly expanderTarget:HTMLElement;
  declare readonly hasExpanderTarget:boolean;
  declare expandedValue:boolean;
  declare readonly modeValue:string;
  declare readonly inlineValue:boolean;

  private abortController:AbortController|null = null;

  // Server-rendered visibility of the expander, captured before the first update.
  // In dialog mode (inline: false) a server-visible expander is kept visible (it may
  // reflect omitted content that physical truncation cannot detect), while a
  // server-hidden expander is toggled based on the current truncation state.
  private serverExpanderVisible?:boolean;

  connect() {
    useResize(this, { element: this.truncateTarget });
    this.update();
  }

  resize() {
    this.update();
  }

  expanderTargetConnected(_target:HTMLElement) {
    if (this.inlineValue) {
      this.abortController = new AbortController();
      const { signal } = this.abortController;
      this.expanderButton.addEventListener('click', () => this.expanderClicked(), { signal });
    } else {
      // The button opens a modal dialog (aria-haspopup="dialog"), so the
      // disclosure-style aria-expanded that HellipButton hardcodes does not apply.
      this.expanderButton.removeAttribute('aria-expanded');
    }
  }

  expanderTargetDisconnected(_target:HTMLElement) {
    this.abortController?.abort();
  }

  expandedValueChanged(value:boolean) {
    if (this.inlineValue && this.hasExpanderTarget) {
      this.expanderButton.setAttribute('aria-label', value ? I18n.t('js.label_collapse_text') : I18n.t('js.label_expand_text'));
      this.expanderButton.setAttribute('aria-expanded', String(value));

      if (this.modeValue === 'multi_line') {
        this.truncateTarget.classList.toggle('op-vertical-truncate--expanded', value);
      } else {
        this.truncateTarget.classList.toggle('Truncate--expanded', value);
      }
    }
    this.update();
  }

  get expanderButton():HTMLButtonElement {
    return this.expanderTarget.querySelector<HTMLButtonElement>('button')!;
  }

  private update() {
    if (!this.hasExpanderTarget) return;

    this.serverExpanderVisible ??= !this.expanderTarget.hidden;

    let truncated:boolean;
    if (this.modeValue === 'multi_line') {
      truncated = this.truncateTarget.scrollHeight > this.truncateTarget.clientHeight;
    } else {
      const truncateText = this.truncateTarget.querySelector<HTMLElement>('.Truncate-text')!;
      truncated = truncateText.scrollWidth > truncateText.clientWidth;
    }

    if (this.inlineValue) {
      this.expanderTarget.hidden = !truncated && !this.expandedValue;
    } else if (this.serverExpanderVisible) {
      this.expanderTarget.hidden = false;
    } else {
      this.expanderTarget.hidden = !truncated;
    }
  }

  private expanderClicked() {
    this.expandedValue = !this.expandedValue;
  }
}
