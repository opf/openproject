//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
//++

import {wpDirectivesModule} from '../../../angular-modules';
import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {UploadFile} from '../../api/op-file-upload/op-file-upload.service';
import {HalResource} from '../../api/api-v3/hal-resources/hal-resource.service';
import {WorkPackageNotificationService} from '../../wp-edit/wp-notification.service';

export class WorkPackageAttachmentListController {
  public workPackage: WorkPackageResourceInterface;
  public text: any = {};

  public itemTemplateUrl =
    '/components/wp-attachments/wp-attachment-list/wp-attachment-list-item.html';

  constructor(protected wpNotificationsService:WorkPackageNotificationService, I18n:op.I18n) {
    this.text = {
      destroyConfirmation: I18n.t('js.text_attachment_destroy_confirmation'),
      removeFile: (arg:any) => I18n.t('js.label_remove_file', arg)
    };

    if (this.workPackage.attachments) {
      this.workPackage.attachments.updateElements();
    }
  }
}

function wpAttachmentListDirective() {
  return {
    restrict: 'E',
    templateUrl: '/components/wp-attachments/wp-attachment-list/wp-attachment-list.directive.html',

    scope: {
      workPackage: '='
    },

    controller: WorkPackageAttachmentListController,
    controllerAs: '$ctrl',
    bindToController: true
  };
}

wpDirectivesModule.directive('wpAttachmentList', wpAttachmentListDirective);
