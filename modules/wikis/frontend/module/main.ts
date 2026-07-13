// -- copyright
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
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.

import { CUSTOM_ELEMENTS_SCHEMA, Injector, NgModule, inject } from '@angular/core';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpSharedModule } from 'core-app/shared/shared.module';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { OpenprojectTabsModule } from 'core-app/shared/components/tabs/openproject-tabs.module';
import {
  WorkPackageTabsService,
} from 'core-app/features/work-packages/components/wp-tabs/services/wp-tabs/wp-tabs.service';

import { WikisTabComponent } from './wikis-tab/wikis-tab.component';

export function initializeWikiPlugin(injector:Injector) {
  const wpTabService = injector.get(WorkPackageTabsService);
  const configService = injector.get(ConfigurationService);
  const I18n = injector.get(I18nService);
  wpTabService.registerAfter(
    'relations',
    {
      component: WikisTabComponent,
      name: I18n.t('js.work_packages.tabs.wikis'),
      id: 'wikis',
      displayable: (workPackage) => configService.wikisAvailable && configService.activeFeatureFlags.includes("wikiEnhancements"),
    },
  );
}

@NgModule({
  imports: [
    OpSharedModule,
    OpenprojectTabsModule,
  ],
  declarations: [
    WikisTabComponent,
  ],
  exports: [
    WikisTabComponent,
  ],
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
})
export class PluginModule {
  constructor() {
    const injector = inject(Injector);

    initializeWikiPlugin(injector);
  }
}
