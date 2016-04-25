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

import {wpButtonsModule} from '../../../angular-modules';
import {WorkPackageButtonController, wpButtonDirective} from '../wp-buttons.module';
import WorkPackageFiltersService from "../../filters/wp-filters/wp-filters.service";

interface Filter {
  modelName:string;
  name:string;
  operator:string;
  type:string;
  values:Object[];
}

export class WorkPackageFilterButtonController extends WorkPackageButtonController {
  public filters:Filter[];

  public labelKey:string = 'js.button_filter';
  public textKey:string = 'js.toolbar.filter';
  public buttonId:string = 'work-packages-filter-toggle-button';
  public iconClass:string = 'icon-filter';

  constructor(public I18n, public _, protected wpFiltersService:WorkPackageFiltersService) {
    'ngInject';

    super(I18n);
  }

  public get label():string {
    return this.prefix + this.text.label;
  }

  public get filterCount():number {
    return this._.size(_.where(this.filters, filter => !filter.deactivated));
  }

  public isActive():boolean {
    return this.wpFiltersService.visible;
  }

  public performAction() {
    this.toggleVisibility()
  }

  public toggleVisibility() {
    this.wpFiltersService.toggleVisibility();
  }
}

function wpFilterButton():ng.IDirective {
  return wpButtonDirective({
    templateUrl: '/components/wp-buttons/wp-filter-button/wp-filter-button.directive.html',

    scope: {
      filters: '='
    },

    controller: WorkPackageFilterButtonController
  });
}

wpButtonsModule.directive('wpFilterButton', wpFilterButton);
