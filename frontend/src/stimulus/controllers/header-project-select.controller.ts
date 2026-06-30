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

const STORAGE_KEY = 'openProject-project-select-display-mode';
const VALID_FILTER_MODES = new Set(['all', 'favorited']);
const NON_DEFAULT_FILTER_MODES = new Set(['favorited']);

export default class HeaderProjectSelectController extends Controller {
  connect():void {
    this.element.addEventListener('click', this.onFilterModeClick);

    // Before the overlay becomes visible, inject the stored filter mode into
    // the turbo-frame src so the server renders the correct initial state.
    const popover = this.element.closest<HTMLElement>('[popover]');
    popover?.addEventListener('beforetoggle', this.onBeforeFirstOpen, { once: true });

    // After the outer Turbo frame loads the FilterableTreeView shell, that component
    // makes a second fetch() of its own to populate the tree. We observe aria-busy on
    // the filterable-tree-view element: when it transitions from "true" → "false" the
    // tree is in the DOM and we can scroll the current project into view.
    // { once: true } on the frame event ensures we only attach the observer on the
    // initial open, not on subsequent search-driven reloads of the outer frame.
    const frame = this.element.querySelector('turbo-frame#op-header-project-frame');
    frame?.addEventListener('turbo:frame-load', this.observeFilterableTreeViewLoad, { once: true });
  }

  disconnect():void {
    this.element.removeEventListener('click', this.onFilterModeClick);
  }

  private onBeforeFirstOpen = ():void => {
    const stored = window.OpenProject.guardedLocalStorage(STORAGE_KEY);
    if (!stored || !NON_DEFAULT_FILTER_MODES.has(stored)) return;

    const frame = this.element.querySelector<HTMLElement>('turbo-frame#op-header-project-frame');
    if (!frame) return;

    const src = frame.getAttribute('src');
    if (!src) return;

    const url = new URL(src, window.location.href);
    url.searchParams.set('filter_mode', stored);
    frame.setAttribute('src', url.toString());
  };

  private observeFilterableTreeViewLoad = ():void => {
    const filterableTreeView = this.element.querySelector('filterable-tree-view');
    if (!filterableTreeView) return;

    const observer = new MutationObserver(() => {
      this.onTreeViewLoadFinished(filterableTreeView, observer);
    });

    observer.observe(filterableTreeView, { attributes: true, attributeFilter: ['aria-busy'] });
    // Also check immediately in case aria-busy is already "false" when the observer is attached
    this.onTreeViewLoadFinished(filterableTreeView, observer);
  };

  private onTreeViewLoadFinished(filterableTreeView:Element, observer:MutationObserver):void {
    if (filterableTreeView.getAttribute('aria-busy') === 'false') {
      observer.disconnect();
      this.scrollCurrentProjectIntoView();
    }
  }

  private scrollCurrentProjectIntoView = ():void => {
    const current = this.element.querySelector<HTMLElement>('[role="treeitem"][aria-current="true"]');
    current?.scrollIntoView({ block: 'center' });
  };

  private onFilterModeClick = (event:MouseEvent):void => {
    const button = (event.target as HTMLElement).closest<HTMLElement>('[data-name]');
    if (button?.dataset.name && VALID_FILTER_MODES.has(button.dataset.name)) {
      window.OpenProject.guardedLocalStorage(STORAGE_KEY, button.dataset.name);
    }
  };
}
