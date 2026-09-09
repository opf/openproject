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
  AfterViewInit,
  ChangeDetectionStrategy,
  Component,
  Input,
  OnDestroy,
  OnInit,
  ViewEncapsulation,
  inject,
} from '@angular/core';
import { map } from 'rxjs/operators';
import { renderStreamMessage } from '@hotwired/turbo';
import { TurboHelpers } from 'core-turbo/helpers';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { IUser } from 'core-app/core/state/principals/user.model';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { addFiltersToPath } from 'core-app/core/apiv3/helpers/add-filters-to-path';
import { SELECT_PRINCIPAL_EVENT, SelectPrincipalDetail } from 'core-common/resource-allocation-autocompleter';
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
export class ResourceAllocationAutocompleterComponent
  extends UserAutocompleterComponent
  implements OnInit, AfterViewInit, OnDestroy {
  @Input() public createPlaceholderUserPath:string|undefined;

  readonly currentUserService = inject(CurrentUserService);

  ngOnInit():void {
    super.ngOnInit();

    // Only adds the not-found template; the option and footer templates the
    // user autocompleter applied stay in place.
    this.applyTemplates(ResourceAllocationAutocompleterTemplateComponent, {
      canCreatePlaceholderUser$: this.currentUserService.hasCapabilities$('placeholder_users/create', 'global'),
      createPlaceholderUser: (name:string) => this.openCreatePlaceholderUserDialog(name),
    });
  }

  public openCreatePlaceholderUserDialog(name:string):void {
    if (!this.createPlaceholderUserPath) { return; }

    const url = new URL(this.createPlaceholderUserPath, window.location.origin);
    if (name) { url.searchParams.set('name', name); }

    this.closeSelect();
    TurboHelpers.showProgressBar();

    void fetch(url.toString(), { headers: { Accept: 'text/vnd.turbo-stream.html' } })
      .then((response) => response.text())
      .then((html) => { renderStreamMessage(html); })
      .finally(() => { TurboHelpers.hideProgressBar(); });
  }

  // Bound manually rather than with @HostListener: the event name carries a
  // colon, which Angular reads as a global event target.
  ngAfterViewInit():void {
    super.ngAfterViewInit();

    this.elementRef.nativeElement.addEventListener(SELECT_PRINCIPAL_EVENT, this.selectPrincipal);
  }

  ngOnDestroy():void {
    super.ngOnDestroy();

    this.elementRef.nativeElement.removeEventListener(SELECT_PRINCIPAL_EVENT, this.selectPrincipal);
  }

  private selectPrincipal = (event:Event):void => {
    const { detail } = event as CustomEvent<SelectPrincipalDetail>;
    const filters = new ApiV3FilterBuilder().add('id', '=', [detail.id]);

    this
      .http
      .get<IHALCollection<IUser>>(addFiltersToPath(this.url, filters).toString())
      .pipe(map((collection) => collection._embedded.elements[0]))
      .subscribe((principal:IUser|undefined) => {
        if (!principal) { return; }

        this.changed({
          id: principal.id,
          name: principal.name,
          href: principal._links.self?.href ?? null,
        });
      });
  };
}
