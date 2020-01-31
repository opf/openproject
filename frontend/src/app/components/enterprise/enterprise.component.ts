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

import {Component, Input} from "@angular/core";
import {enterpriseEditionUrl} from "core-app/globals/constants.const";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {EnterpriseTrialModal} from "core-components/enterprise/enterprise-modal/enterprise-trial.modal";
import {OpModalService} from "core-components/op-modals/op-modal.service";
import {Injector} from "@angular/core";


@Component({
  selector: 'enterprise',
  templateUrl: '/app/components/enterprise/enterprise.component.html'
})
export class EnterpriseComponent {
  @Input() public leftMargin:boolean = false;
  @Input() public textMessage:string;
  @Input() public linkMessage:string;
  @Input() public opReferrer:string;

  public text:any = {
    enterpriseFeature: this.I18n.t('js.upsale.ee_only'),
  };

  constructor(protected I18n:I18nService,
              protected opModalService:OpModalService,
              readonly injector:Injector) {
  }

  public openTrialModal() {
    this.opModalService.show(EnterpriseTrialModal, this.injector);
  }

  public eeLink() {
    if (this.opReferrer) {
      return enterpriseEditionUrl + '&op_referrer=' + this.opReferrer;
    } else {
      return enterpriseEditionUrl;
    }
  }
}

DynamicBootstrapper.register({
  selector: 'enterprise', cls: EnterpriseComponent
});
