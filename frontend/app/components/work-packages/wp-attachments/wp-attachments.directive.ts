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
import {WpAttachmentsService} from './wp-attachments.service';
import {WorkPackageNotificationService} from '../../wp-edit/wp-notification.service';


export class WorkPackageAttachmentsController {
  public workPackage:any;
  public hideEmptyFields:boolean;

  public attachments:any[] = [];
  public fetchingConfiguration:boolean = false;
  public files:File[] = [];
  public hasRightToUpload:boolean = false;
  public loading:boolean = false;
  public rejectedFiles:any[] = [];

  public settings = {
    maximumFileSize: Number
  };

  public size:any;

  private currentlyFocussing;

  constructor(protected $scope:any,
              protected $element:ng.IAugmentedJQuery,
              protected $attrs:ng.IAttributes,
              protected $rootScope,
              protected wpAttachments:WpAttachmentsService,
              protected NotificationsService:any,
              protected wpNotificationsService:WorkPackageNotificationService,
              protected I18n:any,
              protected ConfigurationService:any,
              protected ConversionService:any) {

    this.workPackage = $scope.vm.workPackage();

    this.hasRightToUpload = !!(angular.isDefined(this.workPackage.addAttachment) || this.workPackage.isNew);

    this.fetchingConfiguration = true;
    ConfigurationService.api().then(settings => {
      this.settings.maximumFileSize = settings.maximumAttachmentFileSize;
      this.fetchingConfiguration = false;
    });

    if (this.workPackage && this.workPackage.attachments) {
      this.loadAttachments();
    }

    $rootScope.$on('work_packages.attachment.add', file => {
      this.attachments.push(file);
    });

    $rootScope.$on('work_packages.attachment.updated', () => {
      this.attachments = this.workPackage.attachments.elements;
    });
  }

  public upload():void {
    if (this.workPackage.isNew) {
      this.files.forEach((file) => {
        this.attachments.push(file);
      });
      return;
    }

    if (this.files.length > 0) {
      this.wpAttachments.upload(this.workPackage, this.files).then(() => {
        this.files = [];
        this.loadAttachments();
      });
    }
  };

  public loadAttachments(refresh:boolean = true):ng.IPromise<any> {
    this.loading = true;
    return this.wpAttachments.load(this.workPackage, refresh)
      .then(attachments => {
        this.attachments = attachments;
      }).finally(() => {
        this.loading = false;
      });
  }

  public remove(file):void {
    if (file._type === 'Attachment') {
      file.delete().catch(error => {
        this.wpNotificationsService.handleErrorResponse(error, this.workPackage);
      });
    }

    _.remove(this.attachments, file);
  }

  public focus(attachment:any):void {
    this.currentlyFocussing = attachment;
  };

  public focussing(attachment:any):boolean {
    return this.currentlyFocussing === attachment;
  };

  public filterFiles(files):void {
    // Directories cannot be uploaded and as such, should not become files in
    // the sense of this directive.  The files within the directories will
    // be taken though.
    _.remove(files, (file:any) => {
      return file.type === 'directory';
    });
  };

  public uploadFilteredFiles(files):void {
    this.filterFiles(files);
    this.upload();
  }
}

function wpAttachmentsDirective():ng.IDirective {
  return {
    bindToController: true,
    controller: WorkPackageAttachmentsController,
    controllerAs: 'vm',
    replace: true,
    restrict: 'E',
    scope: {
      workPackage: '&',
      hideEmptyFields: '='
    },
    templateUrl: '/components/work-packages/wp-attachments/wp-attachments.directive.html'
  };
}

wpDirectivesModule.directive('wpAttachments', wpAttachmentsDirective);
