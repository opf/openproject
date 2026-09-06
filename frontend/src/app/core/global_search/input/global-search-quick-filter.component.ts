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

import {
  ChangeDetectionStrategy,
  Component,
  CUSTOM_ELEMENTS_SCHEMA,
  ElementRef,
  ViewChild,
  effect,
  inject,
  input,
  output,
  signal,
} from '@angular/core';
import type { SelectPanelElement } from '@primer/view-components/app/components/primer/alpha/select_panel_element';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { DynamicIconDirective } from 'core-app/shared/components/primer/dynamic-icon.directive';
import { generateId } from 'core-app/shared/helpers/dom-helpers';

interface SelectPanelItemActivatedEvent {
  value:string;
}

@Component({
  selector: 'op-global-search-quick-filter',
  templateUrl: './global-search-quick-filter.component.html',
  imports: [DynamicIconDirective],
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class GlobalSearchQuickFilterComponent {
  private readonly I18n = inject(I18nService);

  @ViewChild('selectPanel', { static: true }) selectPanel:ElementRef<SelectPanelElement>;

  readonly label = input.required<string>();
  readonly options = input.required<readonly string[]>();
  readonly labels = input.required<Record<string, string>>();
  readonly selectedValue = input.required<string>();
  readonly valueChange = output<string>();

  readonly panelId = generateId('global-search-quick-filter');
  readonly pendingValue = signal('');
  readonly filterLabel = this.I18n.t('js.toolbar.filter');
  readonly applyLabel = this.I18n.t('js.modals.button_apply');
  readonly closeLabel = this.I18n.t('js.button_close');
  readonly noResultsLabel = this.I18n.t('js.label_no_data');

  constructor() {
    effect(() => this.pendingValue.set(this.selectedValue()));
  }

  get buttonId():string {
    return `${this.panelId}-button`;
  }

  get dialogId():string {
    return `${this.panelId}-dialog`;
  }

  get titleId():string {
    return `${this.dialogId}-title`;
  }

  get filterId():string {
    return `${this.panelId}-filter`;
  }

  get bodyId():string {
    return `${this.panelId}-body`;
  }

  get listId():string {
    return `${this.panelId}-list`;
  }

  onItemActivated(event:Event):void {
    const value = (event as CustomEvent<SelectPanelItemActivatedEvent>).detail.value;
    this.pendingValue.set(value);
    this.synchronizeSelection(value);
  }

  resetSelection():void {
    const value = this.selectedValue();
    this.pendingValue.set(value);
    this.synchronizeSelection(value);
  }

  apply():void {
    this.valueChange.emit(this.pendingValue());
    this.selectPanel.nativeElement.hide();
  }

  private synchronizeSelection(value:string):void {
    this.selectPanel.nativeElement
      .querySelectorAll<HTMLElement>('[role="option"]')
      .forEach((item) => item.setAttribute('aria-selected', String(item.dataset.value === value)));
  }
}
