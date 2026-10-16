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

import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import {
  EditFieldComponent,
} from 'core-app/shared/components/fields/edit/edit-field.component';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';
import { CallableHalLink } from 'core-app/features/hal/hal-link/hal-link';
import {
  ILabelAutocompleteItem,
} from 'core-app/shared/components/autocompleter/labels-autocompleter/labels-autocompleter.component';

@Component({
  templateUrl: './labels-edit-field.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class LabelsEditFieldComponent extends EditFieldComponent {
  readonly halResourceService = inject(HalResourceService);

  isNew = isNewResource(this.resource as { id:string|null });

  url:string;

  public text = {
    save: this.I18n.t('js.inplace.button_save', { attribute: this.schema.name }),
    cancel: this.I18n.t('js.inplace.button_cancel', { attribute: this.schema.name }),
  };

  initialize():void {
    const link = this.schema.allowedValues as CallableHalLink|undefined;
    if (link) {
      this.url = link.$link.href!;
    }
  }

  public onModelChange(labels?:ILabelAutocompleteItem[]):void {
    this.value = (labels ?? []).map(
      ({ id, name, href }) => this.halResourceService.createHalResourceOfType('Label', { id, name, href }),
    );
  }
}
