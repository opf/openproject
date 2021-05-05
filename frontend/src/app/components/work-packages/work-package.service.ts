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

import { StateService } from '@uirouter/core';
import { Injectable } from "@angular/core";
import { HttpClient } from "@angular/common/http";
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { UrlParamsHelperService } from "core-components/wp-query/url-params-helper";
import { NotificationsService } from "core-app/modules/common/notifications/notifications.service";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { HalDeletedEvent, HalEventsService } from "core-app/modules/hal/services/hal-events.service";

@Injectable()
export class WorkPackageService {

  private text = {
    successful_delete: this.I18n.t('js.work_packages.message_successful_bulk_delete')
  };

  constructor(private readonly http:HttpClient,
              private readonly $state:StateService,
              private readonly PathHelper:PathHelperService,
              private readonly UrlParamsHelper:UrlParamsHelperService,
              private readonly NotificationsService:NotificationsService,
              private readonly I18n:I18nService,
              private readonly halEvents:HalEventsService) {
  }

  public performBulkDelete(ids:string[], defaultHandling:boolean) {
    const params = {
      'ids[]': ids
    };
    const promise = this.http
      .delete(
        this.PathHelper.workPackagesBulkDeletePath(),
        { params: params, withCredentials: true }
      )
      .toPromise();

    if (defaultHandling) {
      promise
        .then(() => {
          this.NotificationsService.addSuccess(this.text.successful_delete);

          ids.forEach(id => this.halEvents.push({ _type:'WorkPackage', id: id }, { eventType: 'deleted' } as HalDeletedEvent));

          if (this.$state.includes('**.list.details.**')
            && ids.indexOf(this.$state.params.workPackageId) > -1) {
            this.$state.go('work-packages.partitioned.list', this.$state.params);
          }
        })
        .catch(() => {
          const urlParams = this.UrlParamsHelper.buildQueryString(params);
          window.location.href = this.PathHelper.workPackagesBulkDeletePath() + '?' + urlParams;
        });
    }

    return promise;
  }
}
