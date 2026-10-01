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

import { Directive } from '@angular/core';
import { EditFieldComponent } from 'core-app/shared/components/fields/edit/edit-field.component';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';

export interface InlineOption {
  name:string;
  href:string|null;
}

@Directive()
export abstract class InlineOptionsEditFieldDirective extends EditFieldComponent {
  public availableOptions:HalResource[] = [];

  public readonly emptyOption:InlineOption = { name: this.I18n.t('js.placeholders.default'), href: null };

  public text = {
    save: this.I18n.t('js.inplace.button_save', { attribute: this.schema.name }),
    cancel: this.I18n.t('js.inplace.button_cancel', { attribute: this.schema.name }),
  };

  protected initialize():void {
    void this.change.getForm()
      .then(() => this.loadOptions())
      .catch(() => console.error('Failed to load allowed values'));
  }

  protected get values():Record<string, unknown> {
    return this.resource as Record<string, unknown>;
  }

  private async loadOptions():Promise<void> {
    const allowedValues = this.schema.allowedValues as HalResource[]|HalResource|undefined;
    let elements:HalResource[] = [];

    if (Array.isArray(allowedValues)) {
      elements = allowedValues;
    } else if (allowedValues) {
      const collection = await (allowedValues.$load() as Promise<CollectionResource>);
      elements = collection.elements;
    }

    this.availableOptions = elements.filter((option) => !!option.name);
    this.cdRef.markForCheck();
  }
}
