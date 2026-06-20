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
import type {
  SelectPanelElement,
  SelectPanelItem,
} from '@primer/view-components/app/components/primer/alpha/select_panel_element';

const FRAME_ID = 'backlogs_container';

// Drives a backlog filter select panel. Submission is explicit:
//
//   * Apply  - navigates the backlogs frame with the current selection.
//   * Clear  - deselects everything and navigates with an empty selection.
//   * Close  - the native dialog dismiss (X / Escape / click-away). It does
//              NOT submit; instead the selection is reverted to the applied
//              filter, so the panel always mirrors what is actually applied.
//
// The applied filter is read from the URL, which is the single source of truth
// for both the "has it changed?" check (Apply/Clear enablement) and the revert
// target. The selection is serialized into the compact comma form
// (?bucket_ids=1,2,inbox); Backlogs::BacklogFilters parses both that and the
// legacy array form on the server.
export default class BacklogFilterSelectPanelController extends Controller<HTMLElement> {
  static values = {
    filterKey: String,
  };

  static targets = ['applyButton', 'clearButton'];

  declare filterKeyValue:string;
  declare readonly applyButtonTarget:HTMLButtonElement;
  declare readonly clearButtonTarget:HTMLButtonElement;
  declare readonly hasApplyButtonTarget:boolean;
  declare readonly hasClearButtonTarget:boolean;

  // Suppresses re-entrancy: Primer's checkItem/uncheckItem fire itemActivated,
  // which would otherwise recurse through refreshButtons while we are setting
  // the selection programmatically.
  private reverting = false;

  // Each controller submits at most once; the frame reload that follows
  // replaces it. Also tells the close handler that a submit is in flight, so it
  // does not revert a selection that is about to be re-rendered.
  private submitted = false;

  refreshButtons():void {
    if (this.reverting) return;

    const current = this.selectedValues();
    if (this.hasApplyButtonTarget) {
      this.applyButtonTarget.disabled = sameMembers(current, this.appliedValues());
    }
    if (this.hasClearButtonTarget) {
      this.clearButtonTarget.disabled = current.length === 0;
    }
  }

  revertOnClose():void {
    if (this.submitted) return; // a submit is navigating; the reload will re-render

    this.setSelection([...this.appliedValues()]);
    this.refreshButtons();
  }

  apply():void {
    this.navigateWith(this.selectedValues());
  }

  clear():void {
    this.setSelection([]);
    this.refreshButtons();

    // Navigating reloads the frame, which closes the panel. When the filter is
    // already empty there is nothing to submit, so close the panel directly.
    if (!this.navigateWith([])) {
      this.panel?.hide();
    }
  }

  // Navigation seam: overridable so specs can assert the target URL without
  // stubbing the Turbo module.
  protected visit(url:string):void {
    Turbo.visit(url, { frame: FRAME_ID, action: 'advance' });
  }

  // Returns false (no navigation) when the selection already matches the
  // applied filter.
  private navigateWith(values:string[]):boolean {
    if (this.submitted || sameMembers(values, this.appliedValues())) return false;

    const url = new URL(window.location.href);
    if (values.length > 0) {
      url.searchParams.set(this.filterKeyValue, values.join(','));
    } else {
      url.searchParams.delete(this.filterKeyValue);
    }

    this.submitted = true;
    this.visit(url.toString());
    return true;
  }

  private setSelection(values:string[]):void {
    const panel = this.panel;
    if (!panel) return;

    const wanted = new Set(values);
    this.reverting = true;
    panel.items.forEach((item) => {
      const value = this.itemValue(item);
      if (value === null) return;

      if (wanted.has(value)) {
        panel.checkItem(item);
      } else {
        panel.uncheckItem(item);
      }
    });
    this.reverting = false;
  }

  private selectedValues():string[] {
    return (this.panel?.selectedItems ?? [])
      .map((item) => item.value)
      .filter((value):value is string => value != null && value.length > 0);
  }

  private appliedValues():Set<string> {
    const raw = new URL(window.location.href).searchParams.get(this.filterKeyValue);
    return new Set(raw ? raw.split(',').map((value) => value.trim()).filter(Boolean) : []);
  }

  // Swappable once Primer exposes a public value accessor on panel items.
  private itemValue(item:SelectPanelItem):string|null {
    return item.querySelector('.ActionListContent')?.getAttribute('data-value') ?? null;
  }

  private get panel():SelectPanelElement|null {
    return this.element.querySelector<SelectPanelElement>('select-panel');
  }
}

// Order-insensitive comparison of two value collections.
function sameMembers(a:Iterable<string>, b:Iterable<string>):boolean {
  return key(a) === key(b);
}

function key(values:Iterable<string>):string {
  return [...values].filter(Boolean).sort()
    .join(',');
}
