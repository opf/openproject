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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { contextColumnIcon, OpTableAction } from 'core-app/features/work-packages/components/wp-table/table-actions/table-action';
import { opIconElement } from 'core-app/shared/helpers/op-icon-builder';

import { StateService } from '@uirouter/core';
import { KeepTabService } from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';
import { UiStateLinkBuilder } from 'core-app/features/work-packages/components/wp-fast-table/builders/ui-state-link-builder';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';

export const detailsLinkClassName = 'wp-table--details-link';

export class OpDetailsTableAction extends OpTableAction {
  public readonly identifier = 'open-details-action';

  private uiStatebuilder = new UiStateLinkBuilder(
    this.injector.get(KeepTabService),
    this.injector.get(CurrentProjectService),
    this.injector.get(PathHelperService),
    this.injector.get(UrlParamsService),
    this.injector.get(StateService));

  private text = {
    button: this.I18n.t('js.button_open_details'),
  };

  public buildElement() {
    // Append details button
    const detailsLink = this.uiStatebuilder.linkToDetails(
      this.workPackage.id!,
      this.text.button,
      '',
      this.workPackage.displayId,
    );

    detailsLink.classList.add(detailsLinkClassName, contextColumnIcon, 'hidden-for-mobile');
    detailsLink.appendChild(opIconElement('icon', 'icon-info2'));

    return detailsLink;
  }
}
