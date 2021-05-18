//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++
import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { IconModule } from 'core-app/modules/icon/icon.module';
import { AttributeHelpTextModule } from 'core-app/modules/attribute-help-texts/attribute-help-text.module';
import { FocusModule } from "core-app/modules/focus/focus.module";
import { ScrollableTabsComponent } from "core-app/modules/common/tabs/scrollable-tabs/scrollable-tabs.component";
import { ContentTabsComponent } from "core-app/modules/common/tabs/content-tabs/content-tabs.component";
import { TabCountComponent } from "core-app/modules/common/tabs/tab-badges/tab-count.component";
import { UIRouterModule } from "@uirouter/angular";

@NgModule({
  imports: [
    CommonModule,
    FocusModule,
    IconModule,
    AttributeHelpTextModule,
    UIRouterModule,
  ],
  exports: [
    ScrollableTabsComponent,
  ],
  declarations: [
    ScrollableTabsComponent,
    ContentTabsComponent,
    TabCountComponent,
  ],
})
export class OpenprojectTabsModule {
}
