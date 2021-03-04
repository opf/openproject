//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
//++

import {Component, ElementRef, Input, OnInit} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';
import {TimezoneService} from 'core-components/datetime/timezone.service';
import {APIV3Service} from "core-app/modules/apiv3/api-v3.service";
import {PrincipalHelper} from "core-app/modules/common/principal/principal-helper";
import PrincipalPluralType = PrincipalHelper.PrincipalPluralType;
import {PrincipalLike, PrincipalRendererService} from "core-app/modules/common/principal/principal-renderer.service";

@Component({
  template: '',
  selector: 'op-principal',
  host: {'class': 'op-principal'}
})
export class OpPrincipalComponent implements OnInit {
  /** If coming from angular, pass a principal resource if available */
  @Input() principal:PrincipalLike;
  @Input() renderAvatar:boolean = true;
  @Input() renderName:boolean = true;
  @Input() avatarClasses:string = '';

  public constructor(readonly elementRef:ElementRef,
                     readonly PathHelper:PathHelperService,
                     readonly principalRenderer:PrincipalRendererService,
                     readonly I18n:I18nService,
                     readonly apiV3Service:APIV3Service,
                     readonly timezoneService:TimezoneService) {

  }

  ngOnInit() {
    const element = this.elementRef.nativeElement;

    if (!this.principal) {
      this.principal = this.principalFromDataset(element);
      this.renderAvatar = element.dataset.renderAvatar === 'true';
      this.renderName = element.dataset.renderName === 'true';
      this.avatarClasses = element.dataset.avatarClasses ?? '';
    }

    this.principalRenderer.render(
      element,
      this.principal,
      this.renderName,
      this.renderAvatar ? { classes: this.avatarClasses } : false
    );
  }

  private principalFromDataset(element:HTMLElement) {
    const id = element.dataset.principalId!;
    const type = element.dataset.principalType;
    const plural = type + 's' as PrincipalPluralType;
    const href = this.apiV3Service[plural].id(id).toString();

    return {
      id: id,
      name: element.dataset.principalName!,
      href: href
    }
  }
}
