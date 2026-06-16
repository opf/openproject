//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

import { StateService } from '@uirouter/core';
import { KeepTabService } from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';
import { UiStateLinkBuilder } from 'core-app/features/work-packages/components/wp-fast-table/builders/ui-state-link-builder';
import { WorkPackageDisplayField } from 'core-app/shared/components/fields/display/field-types/work-package-display-field.module';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';

export class LinkedWorkPackageDisplayField extends WorkPackageDisplayField {
  public text = {
    linkTitle: this.I18n.t('js.work_packages.message_successful_show_in_fullscreen'),
    none: this.I18n.t('js.filter.noneElement'),
  };

  @LazyInject() $state!:StateService;

  @LazyInject() keepTab!:KeepTabService;

  @LazyInject() currentProject!:CurrentProjectService;

  @LazyInject() pathHelper!:PathHelperService;

  private uiStateBuilder:UiStateLinkBuilder = new UiStateLinkBuilder(this.$state, this.keepTab, this.currentProject, this.pathHelper);

  public render(element:HTMLElement, displayText:string):void {
    if (this.isEmpty()) {
      element.innerText = this.placeholder;
      return;
    }

    const routingId = this.wpRoutingId;
    const link = this.uiStateBuilder.linkToShow(
      this.wpId,
      this.text.linkTitle,
      this.valueString,
      routingId,
    );

    const title = document.createElement('span');
    title.textContent = ` ${_.truncate(this.title, { length: 40 })}`;

    element.innerHTML = '';
    element.appendChild(link);
    element.appendChild(title);
  }

  public get writable():boolean {
    return false;
  }

  public get valueString() {
    return this.wpFormattedId;
  }
}
