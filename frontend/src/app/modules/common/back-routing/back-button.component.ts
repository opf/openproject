// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {ChangeDetectionStrategy, Component, Input} from '@angular/core';
import {BackRoutingService} from "core-app/modules/common/back-routing/back-routing.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

@Component({
  template: `
    <div class="wp-show--back-button hide-when-print">
      <accessible-by-keyboard (execute)="goBack()"
                              [linkClass]="classes()"
                              [linkAriaLabel]="text.goBack"
                              [linkTitle]="text.goBack">
        <op-icon icon-classes="button--icon icon-back-up"></op-icon>
      </accessible-by-keyboard>
    </div>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'back-button',
})
export class BackButtonComponent {
  @Input() public linkClass:string;
  @Input() public customBackMethod:Function;

  public text = {
    goBack: this.I18n.t('js.button_back')
  };

  constructor(readonly backRoutingService:BackRoutingService,
              readonly I18n:I18nService) {
  }

  public goBack() {
    if (this.customBackMethod) {
      this.customBackMethod();
    } else {
      this.backRoutingService.goBack();
    }
  }

  public classes():string {
    let classes = 'button ';
    classes += this.linkClass ? this.linkClass : '';

    return classes;
  }
}
