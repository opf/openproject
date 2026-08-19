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

import { ChangeDetectorRef, Directive, OnInit, inject } from '@angular/core';
import { UIRouterGlobals } from '@uirouter/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { WpSingleViewService } from 'core-app/features/work-packages/routing/wp-view-base/state/wp-single-view.service';
import { BrowserDetector } from 'core-app/core/browser/browser-detector.service';
import { DeviceService } from 'core-app/core/browser/device.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { UrlHelpers } from 'core-stimulus/controllers/dynamic/work-packages/activities-tab/services/url-helpers';

@Directive()
export class ActivityPanelBaseController extends UntilDestroyedMixin implements OnInit {
  readonly apiV3Service = inject(ApiV3Service);
  readonly I18n = inject(I18nService);
  readonly cdRef = inject(ChangeDetectorRef);
  readonly uiRouterGlobals = inject(UIRouterGlobals);
  readonly storeService = inject(WpSingleViewService);
  readonly browserDetector = inject(BrowserDetector);
  readonly deviceService = inject(DeviceService);
  readonly pathHelper = inject(PathHelperService);

  public workPackage:WorkPackageResource;

  public workPackageId:string;

  public turboFrameSrc:string;

  ngOnInit():void {
    this.turboFrameSrc = this.buildTurboFrameSrc();
  }

  protected buildTurboFrameSrc():string {
    const baseUrl = window.location.origin;
    const url = new URL(`${this.pathHelper.staticBase}/work_packages/${this.workPackageId}/activities`, baseUrl);
    const anchorInfo = UrlHelpers.extractActivityAnchor(window.location.hash);

    if (anchorInfo) {
      url.searchParams.set('anchor', `${anchorInfo.type}-${anchorInfo.id}`);
    }

    return url.toString();
  }
}
