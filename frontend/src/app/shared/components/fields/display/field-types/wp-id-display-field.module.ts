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

import { KeepTabService } from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';
import { StateService } from '@uirouter/core';
import { UiStateLinkBuilder } from 'core-app/features/work-packages/components/wp-fast-table/builders/ui-state-link-builder';
import { IdDisplayField } from 'core-app/shared/components/fields/display/field-types/id-display-field.module';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';

export class WorkPackageIdDisplayField extends IdDisplayField {
  @LazyInject() $state!:StateService;

  @LazyInject() keepTab!:KeepTabService;

  @LazyInject() currentProject!:CurrentProjectService;

  @LazyInject() pathHelper!:PathHelperService;

  private uiStateBuilder:UiStateLinkBuilder = new UiStateLinkBuilder(this.$state, this.keepTab, this.currentProject, this.pathHelper);

  public get valueString():string {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-return,@typescript-eslint/no-unsafe-member-access
    return this.resource.displayId ?? this.value?.toString() ?? '';
  }

  public render(element:HTMLElement, displayText:string):void {
    if (!this.value) {
      return;
    }
    const link = this.uiStateBuilder.linkToShow(
      // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
      this.value,
      displayText,
      displayText,
      this.valueString,
    );

    element.appendChild(link);
  }
}
