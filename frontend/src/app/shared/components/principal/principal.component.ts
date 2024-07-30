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

import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Input,
  OnInit,
  ViewEncapsulation,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';

import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import {
  AvatarSize,
  PrincipalRendererService,
} from './principal-renderer.service';
import { PrincipalLike } from './principal-types';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';
import { PrincipalType } from 'core-app/shared/components/principal/principal-helper';
import { PrincipalsResourceService } from 'core-app/core/state/principals/principals.service';

export const principalSelector = 'op-principal';

export interface PrincipalInput {
  type:PrincipalType;
  id:string;
}

@Component({
  template: '',
  selector: principalSelector,
  styleUrls: ['./principal.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
})
export class OpPrincipalComponent implements OnInit {
  @Input() principal:PrincipalLike;

  @Input() hideAvatar = false;

  @Input() hideName = false;

  @Input() nameClasses? = '';

  @Input() link = true;

  @Input() size:AvatarSize = 'default';

  @Input() title = '';

  public constructor(
    readonly elementRef:ElementRef,
    readonly PathHelper:PathHelperService,
    readonly principalRenderer:PrincipalRendererService,
    readonly principalResourceService:PrincipalsResourceService,
    readonly I18n:I18nService,
    readonly apiV3Service:ApiV3Service,
    readonly timezoneService:TimezoneService,
    readonly cdRef:ChangeDetectorRef,
  ) {
    populateInputsFromDataset(this);
  }

  ngOnInit() {
    if (this.principal.name) {
      this.principalRenderer.render(
        this.elementRef.nativeElement as HTMLElement,
        this.principal,
        {
          hide: this.hideName,
          link: this.link,
          classes: this.nameClasses,
        },
        {
          hide: this.hideAvatar,
          size: this.size,
        },
        this.title === '' ? null : this.title,
      );
    }
  }
}
