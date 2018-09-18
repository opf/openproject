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

import {combineLatest} from 'rxjs';
import {Subscription} from 'rxjs';
import {HideSectionDefinition, HideSectionService} from "../hide-section.service";
import {openprojectLegacyModule} from "../../../openproject-legacy-app";

export class AddSectionDropdownComponent {
  selectable:HideSectionDefinition[] = [];
  turnedActive:HideSectionDefinition;

  public htmlId:string;
  public i18n:any;

  private allSubscription:Subscription;

  constructor(protected HideSectionService:HideSectionService,
              protected $scope:ng.IScope) {
    window.OpenProject.getPluginContext().then((context) => {
      this.i18n = context.services.i18n;

      this.turnedActive = this.placeholder();

      this.subscribe();
    });
  }

  subscribe() {
    this.allSubscription = combineLatest(this.HideSectionService.all$, this.HideSectionService.displayed$)
      .subscribe(([all, displayed]) => {
        this.selectable = _.filter(all, (all_candidate:any) =>
          !_.some(displayed, (displayed_candidate:any) => all_candidate.key === displayed_candidate.key)
        ).sort((a:any, b:any) => a.label.toLowerCase().localeCompare(b.label.toLowerCase()))

        this.selectable.unshift(this.placeholder());

        // HACK to get the values to be displayed right away
        setTimeout(() => this.$scope.$apply());
      });
  }

  $onDestroy() {
    this.allSubscription.unsubscribe();
  }

  show() {
    if (this.turnedActive) {
      this.HideSectionService.show(this.turnedActive);
      setTimeout(() => {
        this.turnedActive = this.placeholder();
        this.$scope.$apply();
      });
    }
  }

  placeholder() {
    return { key: '', label: this.i18n.t('js.placeholders.selection') };
  }
}

openprojectLegacyModule.component('addSectionDropdown', {
  controller: AddSectionDropdownComponent,
  template: require('!!raw-loader!./add-section-dropdown.component.html'),
  bindings: {
    htmlId: '<'
  }
});
