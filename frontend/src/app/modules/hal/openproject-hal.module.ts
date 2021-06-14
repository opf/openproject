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

import { APP_INITIALIZER, ErrorHandler, NgModule } from '@angular/core';
import { HTTP_INTERCEPTORS, HttpClientModule } from '@angular/common/http';
import { initializeHalResourceConfig } from 'core-app/modules/hal/services/hal-resource.config';
import { HalResourceService } from 'core-app/modules/hal/services/hal-resource.service';
import { OpenProjectHeaderInterceptor } from 'core-app/modules/hal/http/openproject-header-interceptor';
import { CommonModule } from "@angular/common";
import { HalResourceNotificationService } from "core-app/modules/hal/services/hal-resource-notification.service";
import { HalAwareErrorHandler } from "core-app/modules/hal/services/hal-aware-error-handler";

@NgModule({
  imports: [
    CommonModule,
    HttpClientModule,
  ],
  providers: [
    { provide: ErrorHandler, useClass: HalAwareErrorHandler },
    { provide: HTTP_INTERCEPTORS, useClass: OpenProjectHeaderInterceptor, multi: true },
    { provide: APP_INITIALIZER, useFactory: initializeHalResourceConfig, deps: [HalResourceService], multi: true },
    HalResourceNotificationService
  ]
})
export class OpenprojectHalModule { }

