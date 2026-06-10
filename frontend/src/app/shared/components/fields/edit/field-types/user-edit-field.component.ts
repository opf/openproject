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

import { ChangeDetectionStrategy, Component, OnInit, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import {
  EditFieldComponent,
} from 'core-app/shared/components/fields/edit/edit-field.component';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';
import { IUserAutocompleteItem } from 'core-app/shared/components/autocompleter/user-autocompleter/user-autocompleter.component';
import { CallableHalLink } from 'core-app/features/hal/hal-link/hal-link';

@Component({
  templateUrl: './user-edit-field.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class UserEditFieldComponent extends EditFieldComponent implements OnInit {
  readonly apiV3Service = inject(ApiV3Service);
  readonly http = inject(HttpClient);
  readonly halResourceService = inject(HalResourceService);

  isNew = isNewResource(this.resource);

  url:string;

  initialize():void {
    const link = this.schema.allowedValues as CallableHalLink|undefined;
    if (link) {
      this.url = link.$link.href!;
    }
  }

  public onModelChange(user?:IUserAutocompleteItem):unknown {
    if (user) {
      // We fake a HalResource here because we're using a plain JS object, but the schema loading and editing
      // is part of the older HalResource stack
      const newUser = { ...user };
      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
      this.value = this.halResourceService.createHalResourceOfType('user', newUser);
    } else {
      this.value = null;
    }

    return this.handler.handleUserSubmit();
  }
}
