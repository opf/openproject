// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// ++

import {APP_INITIALIZER, ErrorHandler, NgModule} from '@angular/core';
import {HTTP_INTERCEPTORS, HttpClientModule} from '@angular/common/http';
import {initializeHalResourceConfig} from 'core-app/modules/hal/services/hal-resource.config';
import {HalResourceService} from 'core-app/modules/hal/services/hal-resource.service';
import {ConfigurationDmService} from 'core-app/modules/hal/dm-services/configuration-dm.service';
import {HelpTextDmService} from 'core-app/modules/hal/dm-services/help-text-dm.service';
import {PayloadDmService} from 'core-app/modules/hal/dm-services/payload-dm.service';
import {QueryDmService} from 'core-app/modules/hal/dm-services/query-dm.service';
import {QueryFormDmService} from 'core-app/modules/hal/dm-services/query-form-dm.service';
import {RelationsDmService} from 'core-app/modules/hal/dm-services/relations-dm.service';
import {RootDmService} from 'core-app/modules/hal/dm-services/root-dm.service';
import {TypeDmService} from 'core-app/modules/hal/dm-services/type-dm.service';
import {OpenProjectHeaderInterceptor} from 'core-app/modules/hal/http/openproject-header-interceptor';
import {UserDmService} from 'core-app/modules/hal/dm-services/user-dm.service';
import {ProjectDmService} from 'core-app/modules/hal/dm-services/project-dm.service';
import {GridDmService} from "core-app/modules/hal/dm-services/grid-dm.service";
import {TimeEntryDmService} from './dm-services/time-entry-dm.service';
import {CommonModule} from "@angular/common";
import {NewsDmService} from './dm-services/news-dm.service';
import {StatusDmService} from "core-app/modules/hal/dm-services/status-dm.service";
import {VersionDmService} from "core-app/modules/hal/dm-services/version-dm.service";
import {QueryOrderDmService} from "core-app/modules/hal/dm-services/query-order-dm.service";
import {MembershipDmService} from "core-app/modules/hal/dm-services/membership-dm.service";
import {HalResourceNotificationService} from "core-app/modules/hal/services/hal-resource-notification.service";
import {HalAwareErrorHandler} from "core-app/modules/hal/services/hal-aware-error-handler";

@NgModule({
  imports: [
    CommonModule,
    HttpClientModule,
  ],
  providers: [
    { provide: ErrorHandler, useClass: HalAwareErrorHandler },
    { provide: HTTP_INTERCEPTORS, useClass: OpenProjectHeaderInterceptor, multi: true },
    { provide: APP_INITIALIZER, useFactory: initializeHalResourceConfig, deps: [HalResourceService], multi: true },
    ConfigurationDmService,
    GridDmService,
    HelpTextDmService,
    MembershipDmService,
    NewsDmService,
    PayloadDmService,
    ProjectDmService,
    QueryDmService,
    QueryOrderDmService,
    QueryFormDmService,
    RelationsDmService,
    RootDmService,
    TimeEntryDmService,
    TypeDmService,
    UserDmService,
    StatusDmService,
    VersionDmService,
    HalResourceNotificationService
  ]
})
export class OpenprojectHalModule { }

