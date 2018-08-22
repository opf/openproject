//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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
// See doc/COPYRIGHT.rdoc for more details.
//++

import {Injectable} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {NotificationsService} from 'core-app/modules/common/notifications/notifications.service';
import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {input, InputState} from 'reactivestates';
import {WorkPackageNotificationService} from './../wp-edit/wp-notification.service';
import {Subject} from "rxjs";

@Injectable()
export class CommentService {

  // Replacement for ng1 $scope.$emit on activty-entry to mark comments to be quoted.
  // Should be generalized if needed for more than that.
  public quoteEvents = new Subject<string>();

  constructor(
    readonly I18n:I18nService,
    private wpNotificationsService:WorkPackageNotificationService,
    private NotificationsService:NotificationsService) {
  }

  public createComment(workPackage:WorkPackageResource, comment:string) {
    return workPackage.addComment(
      {comment: comment},
      {'Content-Type': 'application/json; charset=UTF-8'}
    )
      .catch((error:any) => this.errorAndReject(error, workPackage));
  }

  public updateComment(activity:HalResource, comment:string) {
    const options = {
      ajax: {
        method: 'PATCH',
        data: JSON.stringify({comment: comment}),
        contentType: 'application/json; charset=utf-8'
      }
    };

    return activity.update(
      {comment: comment},
      {'Content-Type': 'application/json; charset=UTF-8'}
    ).then((activity:HalResource) => {
      this.NotificationsService.addSuccess(
        this.I18n.t('js.work_packages.comment_updated')
      );

      return activity;
    }).catch((error:any) => this.errorAndReject(error));
  }

  private errorAndReject(error:HalResource, workPackage?:WorkPackageResource) {
    this.wpNotificationsService.handleRawError(error, workPackage);

    // returning a reject will enable to correctly work with subsequent then/catch handlers.
    return Promise.reject(error);
  }
}
