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

import { Component, Input } from '@angular/core';
import { WorkPackageResource } from "core-app/features/hal/resources/work-package-resource";
import { I18nService } from "core-app/core/i18n/i18n.service";

@Component({
  selector: 'tab-header',
  templateUrl: './tab-header.template.html',
  styleUrls: [
    './styles/tab-header.sass'
  ]
})
export class TabHeaderComponent {
  @Input() public workPackage:WorkPackageResource;

  public text = {
    title: this.I18n.t('js.github_integration.tab_header.title'),
    createPrButtonLabel: this.I18n.t('js.github_integration.tab_header.create_pr.label'),
    createPrButtonDescription: this.I18n.t('js.github_integration.tab_header.create_pr.description'),
    gitMenuLabel: this.I18n.t('js.github_integration.tab_header.copy_menu.label'),
    gitMenuDescription: this.I18n.t('js.github_integration.tab_header.copy_menu.description'),
  };

  constructor(readonly I18n:I18nService) {
  }
}
