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

import { ChangeDetectionStrategy, Component, Input, OnInit, inject } from '@angular/core';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { BannersService } from 'core-app/core/enterprise/banners.service';

@Component({
  templateUrl: './enterprise-banner-frame.component.html',
  selector: 'op-enterprise-banner-frame',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class EnterpriseBannerFrameComponent implements OnInit {
  protected pathHelper = inject(PathHelperService);
  protected banners = inject(BannersService);

  @Input() public feature:string;

  @Input() public dismissable = false;

  visible:boolean;
  frameURL:string;
  frameID:string;

  ngOnInit() {
    this.visible = this.banners.showBannerFor(this.feature);
    this.frameURL = this.pathHelper.bannerFramePath(this.feature, this.dismissable);

    const trialSuffix = this.banners.trialling(this.feature) ? '_trial' : '';
    this.frameID = `enterprise_banner_${this.feature}${trialSuffix}`;
  }
}
