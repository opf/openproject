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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Controller } from '@hotwired/stimulus';
import * as Turbo from '@hotwired/turbo';
import type { TurboVisitEvent } from '@hotwired/turbo';
import { WP_ID_URL_PATTERN } from 'core-app/shared/helpers/work-package-id-pattern';

const DETAILS_URL_PATTERN = new RegExp(`/details/(${WP_ID_URL_PATTERN})(?:/|$)`);

export default class StoryController extends Controller<HTMLElement> implements EventListenerObject {
  static values = {
    id: Number,
    displayId: String,
    splitUrl: String,
    fullUrl: String,
  };

  declare idValue:number;
  declare displayIdValue:string;
  declare splitUrlValue:string;
  declare fullUrlValue:string;

  static classes = ['selected'];
  declare readonly selectedClass:string;

  private abortController:AbortController|null = null;
  private clickTimeout:number|null = null;

  connect():void {
    this.abortController = new AbortController();
    const { signal } = this.abortController;

    this.element.addEventListener('click', this, { signal });
    this.element.addEventListener('dblclick', this, { signal });
    this.element.addEventListener('keydown', this, { signal });
    document.addEventListener('turbo:visit', (event:TurboVisitEvent) => {
      this.syncSelectionFromUrl(event.detail.url);
    }, { signal });

    this.syncSelectionFromUrl(window.location.href);
  }

  disconnect():void {
    this.abortController?.abort();
    this.abortController = null;

    if (this.clickTimeout !== null) {
      clearTimeout(this.clickTimeout);
      this.clickTimeout = null;
    }
  }

  private syncSelectionFromUrl(locationUrl:string):void {
    const { pathname } = new URL(locationUrl, window.location.origin);
    const [, id] = DETAILS_URL_PATTERN.exec(pathname) ?? [];
    // Bookmarks and external links may still carry a numeric ID after the
    // switch to semantic mode, so accept either form here.
    if (id !== undefined && (id === this.idValue.toString() || id === this.displayIdValue)) {
      this.markAsSelected();
    } else {
      this.unmarkAsSelected();
    }
  }

  markAsSelected():void {
    this.element.classList.add(this.selectedClass);
    this.element.setAttribute('aria-current', 'true');
  }

  unmarkAsSelected():void {
    this.element.classList.remove(this.selectedClass);
    this.element.removeAttribute('aria-current');
  }

  handleEvent(event:Event):void {
    switch (event.type) {
      case 'click':
        this.onClick(event as MouseEvent);
        break;
      case 'dblclick':
        this.onDblClick(event as MouseEvent);
        break;
      case 'keydown':
        this.onKeydown(event as KeyboardEvent);
        break;
    }
  }

  private onClick(event:MouseEvent):void {
    const target = event.target;
    if (!(target instanceof HTMLElement)) return;

    if (this.shouldIgnoreMouseTarget(target)) return;

    if (this.clickTimeout !== null) return;

    this.clickTimeout = window.setTimeout(() => {
      this.clickTimeout = null;
      this.openSplitPane();
    }, 250);
  }

  private onDblClick(event:MouseEvent):void {
    const target = event.target;
    if (!(target instanceof HTMLElement)) return;

    if (this.shouldIgnoreMouseTarget(target)) return;

    if (this.clickTimeout !== null) {
      clearTimeout(this.clickTimeout);
      this.clickTimeout = null;
    }

    this.openFullPane();
  }

  private onKeydown(event:KeyboardEvent):void {
    if (event.key !== 'Enter' && event.key !== ' ') return;

    const target = event.target;
    if (!(target instanceof HTMLElement)) return;

    if (this.shouldIgnoreKeyboardTarget(target)) return;

    event.preventDefault();
    if (event.key === ' ') return;

    if (event.shiftKey) {
      this.openFullPane();
    } else {
      this.openSplitPane();
    }
  }

  private openSplitPane():void {
    Turbo.visit(this.splitUrlValue, { frame: 'content-bodyRight', action: 'advance' });
  }

  private openFullPane():void {
    Turbo.visit(this.fullUrlValue, { frame: '_top' });
  }

  private shouldIgnoreMouseTarget(target:HTMLElement):boolean {
    return [
      'a',
      'button',
      'clipboard-copy',
      '[data-drag-handle]',
    ].some((selector) => target.closest(selector) !== null);
  }

  private shouldIgnoreKeyboardTarget(target:HTMLElement):boolean {
    return this.shouldIgnoreMouseTarget(target) || [
      'input',
      'textarea',
      'select',
      "[contenteditable='true']",
    ].some((selector) => target.closest(selector) !== null);
  }
}
