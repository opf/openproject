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

import {Component, ElementRef} from "@angular/core";
import {I18nService} from "app/modules/common/i18n/i18n.service";
import {EEActiveTrialBase} from "core-components/enterprise/enterprise-active-trial/ee-active-trial.base";

export const enterpriseActiveSavedTrialSelector = 'enterprise-active-saved-trial';

@Component({
  selector: enterpriseActiveSavedTrialSelector,
  templateUrl: './ee-active-trial.component.html',
  styleUrls: ['./ee-active-trial.component.sass']
})
export class EEActiveSavedTrialComponent extends EEActiveTrialBase {
  public subscriber = this.elementRef.nativeElement.dataset['subscriber'];
  public email = this.elementRef.nativeElement.dataset['email'];
  public company = this.elementRef.nativeElement.dataset['company'];
  public domain = this.elementRef.nativeElement.dataset['domain'];
  public userCount = this.elementRef.nativeElement.dataset['userCount'];
  public startsAt = this.elementRef.nativeElement.dataset['startsAt'];
  public expiresAt = this.elementRef.nativeElement.dataset['expiresAt'];

  constructor(readonly elementRef:ElementRef,
              readonly I18n:I18nService) {
    super(I18n);
  }
}
