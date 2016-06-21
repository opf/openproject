// -- copyright
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
// ++

import {wpServicesModule} from '../../../angular-modules.ts';
import {HalResource} from './../../api/api-v3/hal-resources/hal-resource.service'
import {WorkPackageResourceInterface} from "../../api/api-v3/hal-resources/work-package-resource.service";
type FileListAsArray = FileList & typeFixes.ArrayFix;

export class WpAttachmentsService {
  public attachments: Array<any> = [];

  constructor(
    protected $q: ng.IQService,
    protected $timeout: ng.ITimeoutService,
    protected $http: ng.IHttpService,
    protected Upload,
    protected I18n,
    protected NotificationsService
  ) {}

  public upload(workPackage: WorkPackageResourceInterface, files: FileListAsArray): ng.IPromise<any> {
    const uploadPath: string = workPackage.$links.attachments.$link.href;
    const uploads = _.map(files, (file: File) => {
      var options: Object = {
        fields: {
          metadata: {
            description: (file as any).description,
            fileName: file.name,
          }
        },
        file: file,
        url: uploadPath
      };
      return this.Upload.upload(options);
    });

    // notify the user
    const message = this.I18n.t('js.label_upload_notification', {
      id: workPackage.id,
      subject: workPackage.subject
    });

    const notification = this.NotificationsService.addWorkPackageUpload(message, uploads);
    const allUploadsDone = this.$q.defer();
    this.$q.all(uploads).then(() => {
      this.$timeout(() => { // let the notification linger for a bit
        this.NotificationsService.remove(notification);
        allUploadsDone.resolve();
      }, 700);
    }, function (err) {
      allUploadsDone.reject(err);
    });
    return allUploadsDone.promise;
  }

  public load(workPackage: WorkPackageResource, reload:boolean = false): ng.IPromise<Array<any>> {
    const loadedAttachments = this.$q.defer();

    const path: string = workPackage.$links.attachments.$link.href;
    this.$http.get(path, {cache: !reload}).success((response: any) => {
      _.remove(this.attachments);
      _.extend(this.attachments,response._embedded.elements);
      loadedAttachments.resolve(this.attachments);
    }).error(err => {
      loadedAttachments.reject(err);
    });

    return loadedAttachments.promise;
  };

  public remove(fileOrAttachment: any): void {
    if (fileOrAttachment._type === "Attachment") {
      const path: string = fileOrAttachment._links.self.href;
      this.$http.delete(path).success(() => {
        _.remove(this.attachments, fileOrAttachment);
      })
    }else{
      // pending attachment
      _.remove(this.attachments, fileOrAttachment);
    }
  };

  public hasAttachments(workPackage: WorkPackageResourceInterface): ng.IPromise {
    const existance = this.$q.defer();

    this.load(workPackage).then((attachments:any) => {
      existance.resolve(attachments.length > 0);
    });
    return existance.promise;
  };

  public getCurrentAttachments(): Array<any> {
    return this.attachments;
  };

  public resetAttachmentsList(): void {
    this.attachments.length = 0;
  };

  public addPendingAttachments(files: FileListAsArray | File): void {
    if (angular.isArray(files)) {
      files.forEach(file => {
        this.attachments.push(file);
      });
    }
    else {
      this.attachments.push(files);
    }
  }

  // not in use until furinvaders create is merged
  public uploadPendingAttachments = (wp: WorkPackageResourceInterface): ng.IPromise<any> => {
    if (angular.isDefined(wp) && this.attachments.length > 0){
      return this.upload(wp, this.attachments);
    }
  }
}

wpServicesModule.service('wpAttachments', WpAttachmentsService);
