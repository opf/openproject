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

import {wpDirectivesModule} from '../../angular-modules';
import {WorkPackageNotificationService} from '../wp-edit/wp-notification.service';
import {scopedObservable} from '../../helpers/angular-rx-utils';
import {WorkPackageCacheService} from '../work-packages/work-package-cache.service';
import {WorkPackageResourceInterface} from '../api/api-v3/hal-resources/work-package-resource.service';
import {CollectionResourceInterface} from '../api/api-v3/hal-resources/collection-resource.service';

export class WorkPackageAttachmentsController {
  public workPackage: WorkPackageResourceInterface;
  public text: any;
  public attachments: any[] = [];
  public size: any;
  public loading: boolean = false;

  private currentlyFocusing;

  constructor(protected $scope: any,
              protected wpCacheService: WorkPackageCacheService,
              protected wpNotificationsService: WorkPackageNotificationService,
              protected I18n: op.I18n) {

    this.text = {
      destroyConfirmation: I18n.t('js.text_attachment_destroy_confirmation'),
      removeFile: arg => I18n.t('js.label_remove_file', arg)
    };

    if (this.workPackage && this.workPackage.attachments) {
      this.loadAttachments(false);
    }

    $scope.$on('work_packages.attachment.add', (evt, file) => {
      this.attachments.push(file);
    });

    if (this.workPackage.isNew) {
      this.registerCreateObserver();
    }
    else {
      this.registerEditObserver();
    }
  }

  private registerEditObserver() {
    scopedObservable(this.$scope, this.wpCacheService.loadWorkPackage(<number> this.workPackage.id))
      .subscribe((wp: WorkPackageResourceInterface) => {
        this.workPackage = wp;
        this.loadAttachments(true);
      });
  }

  private registerCreateObserver() {
    scopedObservable(this.$scope, this.wpCacheService.onNewWorkPackage())
      .subscribe((wp: WorkPackageResourceInterface) => {
        wp.uploadAttachments(this.attachments).then(() => {
          // Reload the work package after attachments are uploaded to
          // provide the correct links, in e.g., the description
          this.wpCacheService.loadWorkPackage(<number> wp.id, true);
        });
      });
  }

  public loadAttachments(refresh: boolean = true): ng.IPromise<any> {
    this.loading = true;

    return this.workPackage.attachments.$load(refresh)
      .then((collection: CollectionResourceInterface) => {
        this.attachments.length = 0;
        this.attachments.push(...collection.elements);
      })
      .finally(() => {
        this.loading = false;
      });
  }

  public remove(file): void {
    if (!this.workPackage.isNew && file._type === 'Attachment') {
      file
        .delete()
        .then(() => {
          this.workPackage.updateAttachments();
        })
        .catch(error => {
          this.wpNotificationsService.handleErrorResponse(error, this.workPackage)
        });
    }

    _.pull(this.attachments, file);
  }

  public focus(attachment: any): void {
    this.currentlyFocusing = attachment;
  }

  public focusing(attachment: any): boolean {
    return this.currentlyFocusing === attachment;
  }
}

function wpAttachmentsDirective(): ng.IDirective {
  return {
    restrict: 'E',
    templateUrl: '/components/wp-attachments/wp-attachments.directive.html',
    scope: {
      workPackage: '='
    },

    bindToController: true,
    controller: WorkPackageAttachmentsController,
    controllerAs: '$ctrl'
  };
}

wpDirectivesModule.directive('wpAttachments', wpAttachmentsDirective);
