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

import {wpTabsModule} from "../../angular-modules";
import {RelationsHandler} from "./relations-handler/relations-handler.service";

const iconArrowSuffixes = ['up1', 'down1'];

export class WorkPackageRelationsController {


  public relationType:string;
  public handler:RelationsHandler;
  public btnTitle:string;
  public btnIcon:string;
  public focusElementIndex:number = -2;
  public text:any;
  public expand:boolean = false;

  public get stateClass():string {
    return 'icon-arrow-' + iconArrowSuffixes[+!!this.expand];
  }

  constructor(protected $scope, protected I18n) {
    this.text = {
      title: I18n.t('js.relation_labels.' + this.relationType),
      table: {
        subject: I18n.t('js.work_packages.properties.subject'),
        status: I18n.t('js.work_packages.properties.status'),
        assignee: I18n.t('js.work_packages.properties.assignee')
      },
      relations: {
        empty: I18n.t('js.relations.empty'),
        remove: I18n.t('js.relations.remove')
      }
    };

    $scope.$watch('$ctrl.handler', () => {
      if (this.handler) {
        this.expand = this.expand || !this.handler.isEmpty();
      }
    });
  }

  public toggleExpand() {
    this.expand = !this.expand;
  }

  public isFocused(index:number) {
    return index === this.focusElementIndex;
  }

  public updateFocus(index:number) {
    var length = this.handler.relations.length;

    if (length == 0) {
      this.focusElementIndex = -1;
    }
    else {
      this.focusElementIndex = (index < length) ? index : length - 1;
    }

    this.$scope.$evalAsync(() => this.$scope.$broadcast('updateFocus'));
  }
}

function wpRelationsDirective() {
  return {
    restrict: 'E',
    replace: true,
    templateUrl: '/components/wp-relations/wp-relations.directive.html',

    scope: {
      relationType: '@',
      handler: '=',
      btnTitle: '@buttonTitle',
      btnIcon: '@buttonIcon'
    },

    controller: WorkPackageRelationsController,
    controllerAs: '$ctrl',
    bindToController: true,
  };
}

wpTabsModule.directive('wpRelations', wpRelationsDirective);
