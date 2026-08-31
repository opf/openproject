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

import { Injector, NgModule, inject } from '@angular/core';

import { CurrentUserService } from './current-user.service';
import { CurrentUserStore } from './current-user.store';
import { CurrentUserQuery } from './current-user.query';
import { firstValueFrom } from 'rxjs';
import { getMetaValue } from '../setup/globals/global-helpers';

function loadUserMetadata(currentUserService:CurrentUserService) {
  currentUserService.setUser({
    id: getMetaValue('current_user', 'id', null),
    name: getMetaValue('current_user', 'name', null),
    loggedIn: getMetaValue('current_user', 'loggedIn') === 'true'
  });
}

export function bootstrapModule(injector:Injector):void {
  const currentUserService = injector.get(CurrentUserService);

  window.ErrorReporter
    .addHook(
      () => firstValueFrom(currentUserService.user$)
        .then(({ id }) => ({ user: id || 'anon' })),
    );

  loadUserMetadata(currentUserService);
  document.addEventListener('turbo:load', () => loadUserMetadata(currentUserService));
}

@NgModule({
  providers: [
    CurrentUserService,
    CurrentUserStore,
    CurrentUserQuery,
  ],
})
export class CurrentUserModule {
  constructor() {
    const injector = inject(Injector);

    bootstrapModule(injector);
  }
}
