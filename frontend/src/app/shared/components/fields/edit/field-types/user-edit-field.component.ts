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

import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Inject,
  Injector,
  OnInit,
} from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  EditFieldComponent,
  OpEditingPortalChangesetToken,
  OpEditingPortalHandlerToken,
  OpEditingPortalSchemaToken,
} from 'core-app/shared/components/fields/edit/edit-field.component';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
// import { IProject } from 'core-app/core/state/projects/project.model';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { ResourceChangeset } from '../../changeset/resource-changeset';
import { IFieldSchema } from '../../field.base';
import { EditFieldHandler } from '../editing-portal/edit-field-handler';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';
import { IUserAutocompleteItem } from 'core-app/shared/components/autocompleter/user-autocompleter/user-autocompleter.component';
import { CallableHalLink } from 'core-app/features/hal/hal-link/hal-link';

@Component({
  templateUrl: './user-edit-field.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class UserEditFieldComponent extends EditFieldComponent implements OnInit {
  isNew = isNewResource(this.resource);

  url:string;

  constructor(
    readonly I18n:I18nService,
    readonly elementRef:ElementRef,
    @Inject(OpEditingPortalChangesetToken) protected change:ResourceChangeset<HalResource>,
    @Inject(OpEditingPortalSchemaToken) public schema:IFieldSchema,
    @Inject(OpEditingPortalHandlerToken) readonly handler:EditFieldHandler,
    readonly cdRef:ChangeDetectorRef,
    readonly injector:Injector,
    readonly apiV3Service:ApiV3Service,
    readonly http:HttpClient,
    readonly halResourceService:HalResourceService,
  ) {
    super(
      I18n,
      elementRef,
      change,
      schema,
      handler,
      cdRef,
      injector,
    );
  }

  initialize():void {
    const link = this.schema.allowedValues as CallableHalLink|undefined;
    if (link) {
      this.url = link.$link.href as string;
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
