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

import { ChangeDetectionStrategy, Component, OnInit, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import {
  AutocompleterEditFieldComponent,
} from 'core-app/shared/components/fields/edit/field-types/autocompleter-edit-field.component';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';
import { CallableHalLink } from 'core-app/features/hal/hal-link/hal-link';
import {
  UserSelection,
  createUserSelectionAdapter,
  userSelectionToResource,
} from 'core-app/shared/components/autocompleter/selection/user-selection';

const unloaded = Symbol('unloaded');

@Component({
  templateUrl: './user-edit-field.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class UserEditFieldComponent extends AutocompleterEditFieldComponent implements OnInit {
  readonly apiV3Service = inject(ApiV3Service);
  readonly http = inject(HttpClient);
  readonly halResourceService = inject(HalResourceService);

  readonly selection = createUserSelectionAdapter();

  isNew = isNewResource(this.resource);

  url:string;

  private loadedValue:unknown = unloaded;

  ngOnInit():void {
    this.selection.changes$
      .pipe(this.untilDestroyed())
      .subscribe((value) => this.onSelectionChange(value));

    this.selection.stateChanges$
      .pipe(this.untilDestroyed())
      .subscribe(() => this.cdRef.markForCheck());

    super.ngOnInit();
  }

  initialize():void {
    const link = this.schema.allowedValues as CallableHalLink|undefined;
    if (link) {
      this.url = link.$link.href!;
    }

    if (this.value !== this.loadedValue) {
      this.loadedValue = this.value;
      this.selection.bridge.load(this.value);
    }
  }

  onSelectionChange(value:UserSelection):void {
    this.value = userSelectionToResource(value, {
      halResourceService: this.halResourceService,
      apiV3Service: this.apiV3Service,
    });
    this.loadedValue = this.value;

    void this.handler.handleUserSubmit();
  }
}
