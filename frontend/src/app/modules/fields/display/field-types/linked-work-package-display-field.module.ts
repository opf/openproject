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

import {StateService} from '@uirouter/core';
import {KeepTabService} from 'core-components/wp-single-view-tabs/keep-tab/keep-tab.service';
import {UiStateLinkBuilder} from "core-components/wp-fast-table/builders/ui-state-link-builder";
import {WorkPackageDisplayField} from "core-app/modules/fields/display/field-types/work-package-display-field.module";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";

export class LinkedWorkPackageDisplayField extends WorkPackageDisplayField {

  public text = {
    linkTitle: this.I18n.t('js.work_packages.message_successful_show_in_fullscreen'),
    none: this.I18n.t('js.filter.noneElement')
  };

  @InjectField() $state:StateService;
  @InjectField() keepTab:KeepTabService;

  private uiStateBuilder:UiStateLinkBuilder = new UiStateLinkBuilder(this.$state, this.keepTab);

  public render(element:HTMLElement, displayText:string):void {
    if (this.isEmpty()) {
      element.innerText = this.placeholder;
      return;
    }

    let link = this.uiStateBuilder.linkToShow(
      this.wpId,
      this.text.linkTitle,
      this.valueString
    );

    element.innerHTML = '';
    element.appendChild(link);
  }

  public get writable():boolean {
    return false;
  }

  public get valueString() {
    return '#' + this.wpId;
  }
}
