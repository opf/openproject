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
import IDirective = angular.IDirective;

export class WorkPackageUploadDirectiveController {
  public workPackage: WorkPackageResourceInterface;
  public attachments: any[];
  public text: any;
  public canUpload: boolean = false;
  public maxFileSize: number;
  public files: File[] = [];
  public rejectedFiles: File[] = [];

  constructor(I18n, ConfigurationService) {
    this.text = {
      dropFiles: I18n.t('js.label_drop_files'),
      dropFilesHint: I18n.t('js.label_drop_files_hint')
    };
    this.canUpload = !!this.workPackage.addAttachment || this.workPackage.isNew;

    ConfigurationService.api().then(settings => {
      this.maxFileSize = settings.maximumAttachmentFileSize;
    });
  }

  /**
   * Upload the files provided by ngFileUpload.
   *
   * If the work package is being created, add the files to the provided attachments array.
   * If the work package exists and the user has the permission to upload,
   * upload the files and reset the files array.
   */
  public upload(): void {
    _.remove(this.files, (file: any) => file.type === 'directory');

    if (this.workPackage.isNew) {
      this.attachments.push(...this.files);
    }
    else if (this.files.length > 0) {
      this.workPackage.uploadAttachments(<any> this.files).then(() => {
        this.files = [];
      });
    }
  };
}

function wpUploadDirective(): IDirective {
  return {
    restrict: 'E',
    templateUrl: '/components/wp-attachments/wp-attachments-upload/wp-attachments-upload.directive.html',

    scope: {
      workPackage: '=',
      attachments: '='
    },

    controller: WorkPackageUploadDirectiveController,
    controllerAs: '$ctrl',
    bindToController: true
  };
}

wpDirectivesModule.directive('wpAttachmentsUpload', wpUploadDirective);
