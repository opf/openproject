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

import { AfterViewInit, ChangeDetectionStrategy, Component, ElementRef, EventEmitter, Input, OnInit, Output, ViewChild, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { NgSelectComponent } from '@ng-select/ng-select';
import {
  repositionDropdownBugfix,
} from 'core-app/shared/components/autocompleter/op-autocompleter/autocompleter.helper';
import { QueryFilterResource } from 'core-app/features/hal/resources/query-filter-resource';
import { AlternativeSearchService } from 'core-app/shared/components/work-packages/alternative-search.service';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';
import { reorderById } from 'core-common/drag-and-drop/reorder';
import {
  SortableListsDropEvent,
} from 'core-app/shared/directives/sortable-lists/sortable-lists.directive';

export interface DraggableOption {
  name:string;
  id:string;
}

@Component({
  selector: 'op-draggable-autocompleter',
  templateUrl: './draggable-autocomplete.component.html',
  styleUrls: ['./draggable-autocomplete.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class DraggableAutocompleteComponent implements OnInit, AfterViewInit {
  readonly I18n = inject(I18nService);
  readonly elementRef = inject<ElementRef<HTMLElement>>(ElementRef);
  readonly alternativeSearchService = inject(AlternativeSearchService);

  /** Options to show in the autocompleter */
  @Input() options:DraggableOption[];

  /** Order list of selected items */
  @Input() selected:DraggableOption[] = [];

  /** List of options that are protected from being deleted. They can still be moved. */
  @Input() protected:DraggableOption[] = [];

  /** Should we focus the autocompleter ? */
  @Input() autofocus = true;

  @Input() name = '';

  /** Id of the autocompleter input */
  @Input() id = this.name;

  /** Label to display above the autocompleter */
  @Input() inputLabel = '';

  /** Placeholder text to display in the autocompleter input */
  @Input() inputPlaceholder = '';

  /** Label to display below the autocompleter input */
  @Input() inputCaption = '';

  /** Label to display a validation error below the drag&drop area */
  @Input() inputError = '';

  /** Label to display drag&drop area */
  @Input() dragAreaLabel = '';

  /**
   * Name of drag&drop area group.
   *
   * @deprecated Instance isolation no longer relies on a group name; each
   * sortable list is scoped automatically. Kept only so existing
   * custom-element embeddings that still pass the attribute keep working.
   */
  @Input() dragAreaName = 'columns';

  /** Indicates that at least one entry must be selected */
  @Input() required = false;

  /** Decide whether to bind the component to the component or to the body */
  /** Binding to the component in case the component is inside a Primer Dialog which uses popover */
  @Input() appendToComponent = false;
  @Input() formControlId = 'op-draggable-autocomplete-container';

  /** Output when autocompleter changes values or items removed */
  @Output() onChange = new EventEmitter<DraggableOption[]>();

  /** List of items still available for selection */
  availableOptions:DraggableOption[] = [];

  @ViewChild('ngSelectComponent') public ngSelectComponent:NgSelectComponent;

  public appendTo = 'body';

  ngOnInit():void {
    populateInputsFromDataset(this);

    this.updateAvailableOptions();

    this.appendTo = this.appendToComponent ? `#${this.formControlId}` : 'body';
  }

  ngAfterViewInit():void {
    if (this.autofocus) {
      this.ngSelectComponent.focus();
    }

    // Set the id of the input so that it matches the label.
    const input = this.ngSelectComponent.element.querySelector('input');
    if (input) {
      input.id = this.id;
    }
  }

  reorder(event:SortableListsDropEvent):void {
    const reordered = reorderById({
      list: this.selectedOptions,
      getId: (item) => item.id,
      sourceId: event.sourceId,
      targetId: event.targetId,
      closestEdge: event.edge,
      axis: 'horizontal',
    });

    // reorderById returns the original reference for no-op moves, so this
    // only re-renders and emits when the order actually changed.
    if (reordered !== this.selectedOptions) {
      this.selectedOptions = reordered;
    }

    // Completion is synchronous: there is no server round-trip here, the
    // reordered chips simply persist on the next form submit. Completing
    // unconditionally (even for a no-op) is essential — the engine keeps its
    // transaction "busy" until `complete` runs, which blocks the *next*
    // drag from starting if this call is skipped.
    event.complete(true);
  }

  select(item:DraggableOption|undefined) {
    if (!item) {
      return;
    }

    this.selectedOptions = [...this.selectedOptions, item];

    // Remove selection
    this.ngSelectComponent.clearModel();
  }

  remove(item:DraggableOption) {
    this.selectedOptions = this.selectedOptions.filter((selected) => selected.id !== item.id);
  }

  removeLabel(item:DraggableOption):string {
    return this.I18n.t('js.autocomplete_select.remove', { name: item.name });
  }

  isRemovable(item:DraggableOption) {
    return !this.protected.find((protectedItem) => protectedItem.id === item.id);
  }

  get selectedOptions() {
    return this.selected;
  }

  set selectedOptions(val:DraggableOption[]) {
    this.selected = val;
    this.updateAvailableOptions();

    this.onChange.emit(this.selectedOptions);
  }

  get hiddenValue() {
    return this.selectedOptions.map((item) => item.id).join(' ');
  }

  get hiddenValues() {
    return this.selectedOptions.map((item) => item.id);
  }

  get isArrayOfValues() {
    return this.name.endsWith('[]');
  }

  opened() {
    repositionDropdownBugfix(this.ngSelectComponent);
  }

  searchFunction = (term:string, currentItem:QueryFilterResource):boolean => {
    return this.alternativeSearchService.searchFunction(term, currentItem);
  };

  get hasError() {
    return this.required && this.selectedOptions.length === 0;
  }

  get errorMessage() {
    return this.inputError;
  }

  private updateAvailableOptions() {
    this.availableOptions = this.options
      .filter((item) => !this.selectedOptions.find((selected) => selected.id === item.id));
  }
}
