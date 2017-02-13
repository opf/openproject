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
import {WorkPackageRelationsController} from '../wp-relations.directive';


export class WorkPackageRelationsGroupController {
  public relatedWorkPackages:Array<WorkPackageResourceInterface>;
  public workPackage:WorkPackageResourceInterface;
  public header:string;
  public firstGroup:boolean;
  public groupByWorkPackageType:boolean;
  public text:Object;
  public relationsCtrl: WorkPackageRelationsController;

  constructor(public $element:ng.IAugmentedJQuery,
              public $timeout:ng.ITimeoutService,
              public I18n:op.I18n) {
    this.text = {
      groupByType: I18n.t('js.relation_buttons.group_by_wp_type'),
      groupByRelation: I18n.t('js.relation_buttons.group_by_relation_type')
    };
  }

  public toggleButton() {
    this.relationsCtrl.toggleGroupBy();
    this.$timeout(() => {
      this.$element.find('#wp-relation-group-by-toggle').focus();
    });
  }
}

function wpRelationsGroupDirective() {
  return {
    restrict: 'E',
    templateUrl: '/components/wp-relations/wp-relations-group/wp-relations-group.template.html',

    scope: {
      header: '=',
      firstGroup: '=',
      workPackage: '=',
      groupByWorkPackageType: '=',
      relatedWorkPackages: '='
    },

    link: (scope:any,
           element:ng.IAugmentedJQuery,
           attrs:any,
           controllers: [WorkPackageRelationsController]) => {
      scope.$ctrl.relationsCtrl = controllers[0];
    },
    controller: WorkPackageRelationsGroupController,
    controllerAs: '$ctrl',
    require: ['^wpRelations'],
    bindToController: true,
  };
}

wpDirectivesModule.directive('wpRelationsGroup', wpRelationsGroupDirective);
