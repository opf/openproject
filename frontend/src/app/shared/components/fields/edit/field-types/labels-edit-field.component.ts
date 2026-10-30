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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  ChangeDetectionStrategy, Component, OnInit, inject,
} from '@angular/core';
import {
  AutocompleterEditFieldComponent,
} from 'core-app/shared/components/fields/edit/field-types/autocompleter-edit-field.component';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';
import { CallableHalLink } from 'core-app/features/hal/hal-link/hal-link';
import {
  LabelSelection,
  createLabelSelectionAdapter,
  labelSelectionToResources,
  labelSelectionsToModel,
} from 'core-app/shared/components/autocompleter/selection/label-selection';

const unloaded = Symbol('unloaded');
const noLabels:unknown[] = [];

@Component({
  templateUrl: './labels-edit-field.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class LabelsEditFieldComponent extends AutocompleterEditFieldComponent implements OnInit {
  readonly apiV3Service = inject(ApiV3Service);
  readonly halResourceService = inject(HalResourceService);

  readonly selection = createLabelSelectionAdapter();

  isNew = isNewResource(this.resource);

  url:string;

  displayModel:unknown[] = noLabels;

  private loadedValue:unknown = unloaded;

  private writing = false;

  public text = {
    save: this.I18n.t('js.inplace.button_save', { attribute: this.schema.name }),
    cancel: this.I18n.t('js.inplace.button_cancel', { attribute: this.schema.name }),
  };

  ngOnInit():void {
    this.selection.changes$
      .pipe(this.untilDestroyed())
      .subscribe((values) => this.onSelectionChange(values));

    this.selection.stateChanges$
      .pipe(this.untilDestroyed())
      .subscribe(() => {
        this.refreshDisplayModel();
        this.cdRef.markForCheck();
      });

    super.ngOnInit();
  }

  initialize():void {
    const link = this.schema.allowedValues as CallableHalLink|undefined;
    if (link) {
      this.url = link.$link.href!;
    }

    if (!this.writing && this.value !== this.loadedValue) {
      this.loadedValue = this.value;
      this.selection.bridge.load(this.value);
    }
  }

  onSelectionChange(values:LabelSelection[]):void {
    this.writing = true;
    try {
      this.value = labelSelectionToResources(values, {
        halResourceService: this.halResourceService,
        apiV3Service: this.apiV3Service,
      });
    } finally {
      this.writing = false;
    }
    this.loadedValue = this.value;
  }

  private refreshDisplayModel():void {
    const { model } = this.selection.bridge;
    if (Array.isArray(model)) {
      this.displayModel = model as unknown[];
      return;
    }

    const { state } = this.selection;
    const selections = state.kind === 'ready' ? state.value : [];
    this.displayModel = selections.length > 0 ? labelSelectionsToModel(selections) : noLabels;
  }
}
