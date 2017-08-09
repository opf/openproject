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
import IDirective = angular.IDirective;

export class WorkPackageUploadDirectiveController {
  public workPackage: WorkPackageResourceInterface;
  public text: any;
  public maxFileSize: number;

  constructor(protected $q:ng.IQService, ConfigurationService:any, protected I18n:op.I18n) {
    this.text = {
      uploadLabel: I18n.t('js.label_add_attachments')
    };
    ConfigurationService.api().then((settings:any) => {
      this.maxFileSize = settings.maximumAttachmentFileSize;
    });
  }

  public uploadFiles(files: UploadFile[]):void {
    if (files === undefined || files.length === 0) {
      return;
    }

    if (this.workPackage.isNew) {
      this.workPackage.pendingAttachments.push(...files);
      return;
    }

    this.workPackage.uploadAttachments(files);
  }
}

function wpUploadDirective(): IDirective {
  function wpUploadDirectiveLink(scope:ng.IScope, element:ng.IAugmentedJQuery) {
    element.click(() => element.children().first().click());
  }

  return {
    restrict: 'AE',
    template: `
      <div
        class="wp-attachment-upload"
        ng-if="$ctrl.workPackage.canAddAttachments"
        ngf-drop
        ngf-select
        ngf-change="$ctrl.uploadFiles($files)"
        ngf-multiple="true"
        ngf-validate="{ size: {max: ::$ctrl.maxFileSize} }"
        tabindex="0"
        aria-label="{{ ::$ctrl.text.uploadLabel }}"
        click-on-keypress="[13, 32]"
        ng-transclude>
      </div>`,

    transclude: true,

    scope: {
      workPackage: '='
    },

    controller: WorkPackageUploadDirectiveController,
    controllerAs: '$ctrl',
    bindToController: true,

    link: wpUploadDirectiveLink
  };
}

wpDirectivesModule.directive('wpAttachmentsUpload', wpUploadDirective);
