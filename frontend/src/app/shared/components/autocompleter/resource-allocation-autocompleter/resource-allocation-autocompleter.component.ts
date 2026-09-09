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
  OnInit,
  ViewEncapsulation,
  inject,
} from '@angular/core';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import {
  UserAutocompleterComponent,
} from 'core-app/shared/components/autocompleter/user-autocompleter/user-autocompleter.component';
import {
  ResourceAllocationAutocompleterTemplateComponent,
} from 'core-app/shared/components/autocompleter/resource-allocation-autocompleter/resource-allocation-autocompleter-template.component';

export const resourceAllocationAutocompleterSelector = 'op-resource-allocation-autocompleter';

@Component({
  templateUrl: '../op-autocompleter/op-autocompleter.component.html',
  selector: resourceAllocationAutocompleterSelector,
  styleUrls: ['../user-autocompleter/user-autocompleter.component.sass'],
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class ResourceAllocationAutocompleterComponent extends UserAutocompleterComponent implements OnInit {
  readonly currentUserService = inject(CurrentUserService);

  ngOnInit():void {
    super.ngOnInit();

    // Only adds the not-found template; the option and footer templates the
    // user autocompleter applied stay in place.
    this.applyTemplates(ResourceAllocationAutocompleterTemplateComponent, {
      canCreatePlaceholderUser$: this.currentUserService.hasCapabilities$('placeholder_users/create', 'global'),
    });
  }
}
