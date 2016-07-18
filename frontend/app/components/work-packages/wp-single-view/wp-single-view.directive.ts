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

import {opWorkPackagesModule} from '../../../angular-modules';
import {scopedObservable} from '../../../helpers/angular-rx-utils';
import {
  WorkPackageResource,
  WorkPackageResourceInterface
} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageEditFormController} from '../../wp-edit/wp-edit-form.directive';
import {WorkPackageNotificationService} from '../../wp-edit/wp-notification.service';

export class WorkPackageSingleViewController {
  public formCtrl:WorkPackageEditFormController;
  public workPackage:WorkPackageResourceInterface;
  public singleViewWp;
  public groupedFields:any[] = [];
  public hideEmptyFields:boolean = true;
  public attachments:Array<any>;
  public text:any;
  public scope:any;

  protected firstTimeFocused:boolean = false;

  constructor(protected $scope,
              protected $window,
              protected $state,
              protected $stateParams,
              protected loadingIndicator,
              protected I18n,
              protected wpCacheService,
              protected wpNotificationsService:WorkPackageNotificationService,
              protected WorkPackagesOverviewService,
              protected wpAttachments,
              protected SingleViewWorkPackage) {

    var wpId = this.workPackage ? this.workPackage.id : $stateParams.workPackageId;

    this.groupedFields = WorkPackagesOverviewService.getGroupedWorkPackageOverviewAttributes();
    this.text = {
      fields: {
        date: {
          startDate: I18n.t('js.label_no_start_date'),
          dueDate: I18n.t('js.label_no_due_date')
        }
      },
      idLabel: ''
    };

    scopedObservable($scope, wpCacheService.loadWorkPackage(wpId)).subscribe(wp => this.init(wp));
    $scope.$on('workPackageUpdatedInEditor', () => {
      this.wpNotificationsService.showSave(this.workPackage);
    });
  }

  public shouldHideGroup(group) {
    return this.singleViewWp.shouldHideGroup(this.hideEmptyFields, this.groupedFields, group);
  }

  public shouldHideField(field) {
    let hideEmpty = !this.formCtrl.fields[field].hasFocus() && this.hideEmptyFields;

    return this.singleViewWp.shouldHideField(field, hideEmpty);
  };

  public setFocus() {
    if (!this.firstTimeFocused) {
      this.firstTimeFocused = true;
      angular.element('.work-packages--details--subject .focus-input').focus();
    }
  }

  public setIdLabel() {
    if (!this.workPackage.type) {
      return;
    }

    this.text.idLabel = this.workPackage.type.name;
    if (!this.workPackage.isNew) {
      this.text.idLabel += ' #' + this.workPackage.id;
    }
  }

  private init(wp) {
    this.workPackage = wp;
    this.singleViewWp = new this.SingleViewWorkPackage(wp);

    this.workPackage.schema.$load().then(schema => {
      this.setFocus();

      var otherGroup:any = _.find(this.groupedFields, {groupName: 'other'});
      otherGroup.attributes = [];

      angular.forEach(schema, (prop, propName) => {
        if (propName.match(/^customField/)) {
          otherGroup.attributes.push(propName);
        }
      });

      otherGroup.attributes.sort((leftField, rightField) => {
        var getLabel = field => this.singleViewWp.getLabel(field);
        var left = getLabel(leftField).toLowerCase();
        var right = getLabel(rightField).toLowerCase();

        return left.localeCompare(right);
      });
    });

  }
}

function wpSingleViewDirective() {

  function wpSingleViewLink(scope,
                            element,
                            attrs,
                            controllers:[WorkPackageEditFormController, WorkPackageSingleViewController]) {

    controllers[1].formCtrl = controllers[0];

    scope.$watch(_ => controllers[1].workPackage.type, _ => {
      controllers[1].setIdLabel();
    });
  }

  return {
    restrict: 'E',
    templateUrl: '/components/work-packages/wp-single-view/wp-single-view.directive.html',

    scope: {
      workPackage: '=?'
    },

    require: ['^wpEditForm', 'wpSingleView'],
    link: wpSingleViewLink,

    bindToController: true,
    controller: WorkPackageSingleViewController,
    controllerAs: '$ctrl'
  };
}

opWorkPackagesModule.directive('wpSingleView', wpSingleViewDirective);
