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

import { CUSTOM_ELEMENTS_SCHEMA, NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FocusModule } from 'core-app/shared/directives/focus/focus.module';
import { AttributeHelpTextModule } from 'core-app/shared/components/attribute-help-texts/attribute-help-text.module';
import { ScrollableTabsComponent } from 'core-app/shared/components/tabs/scrollable-tabs/scrollable-tabs.component';
import { TabCountComponent } from 'core-app/shared/components/tabs/tab-badges/tab-count.component';
import { IconModule } from 'core-app/shared/components/icon/icon.module';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { PrimerCounterComponent } from 'core-app/shared/components/primer/counter.component';
import { PrimerIconButtonComponent } from 'core-app/shared/components/primer/icon-button.component';
import { TabPanelDirective } from 'core-app/shared/components/tabs/tab-panel.directive';

@NgModule({
  imports: [
    CommonModule,
    FocusModule,
    IconModule,
    AttributeHelpTextModule,
    OpTooltipDirective,
    PrimerCounterComponent,
    PrimerIconButtonComponent,
    TabPanelDirective,
  ],
  exports: [
    ScrollableTabsComponent,
    TabPanelDirective,
  ],
  declarations: [
    ScrollableTabsComponent,
    TabCountComponent,
  ],
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
})
export class OpenprojectTabsModule {
}
