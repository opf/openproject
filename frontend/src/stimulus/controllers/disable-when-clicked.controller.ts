//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Controller } from '@hotwired/stimulus';

export default class DisableWhenClickedController extends Controller<HTMLElement> {
  static values = {
    text: String,
  };

  declare textValue:string;
  private alreadyClicked = false;
  private clickListener = this.handleClick.bind(this);

  connect() {
    super.connect();
    this.element.addEventListener('click', this.clickListener);
  }

  disconnect() {
    this.element.removeEventListener('click', this.clickListener);

    // Reset state so a reconnect (e.g. Turbo cache/restore, or the element
    // being removed and reinserted) starts fresh rather than treating the
    // first click as an already-clicked one.
    this.alreadyClicked = false;
    this.enable();
  }

  private handleClick(event:Event):void {
    if (this.alreadyClicked) {
      event.preventDefault();
      event.stopImmediatePropagation();
      return;
    }

    this.alreadyClicked = true;
    setTimeout(() => this.disable(), 0);
  }

  private disable():void {
    const el = this.element;

    // Only form elements support the `disabled` attribute. For other elements
    // (e.g. anchors) fall back to `aria-disabled`, which keeps them focusable
    // for assistive tech. Actual click prevention is handled by the
    // `alreadyClicked` guard.
    if (el instanceof HTMLButtonElement || el instanceof HTMLInputElement) {
      el.disabled = true;
    } else {
      el.setAttribute('aria-disabled', 'true');
    }

    if (this.textValue) {
      el.textContent = this.textValue;
    }
  }

  private enable():void {
    const el = this.element;

    if (el instanceof HTMLButtonElement || el instanceof HTMLInputElement) {
      el.disabled = false;
    } else {
      el.removeAttribute('aria-disabled');
    }
  }
}
