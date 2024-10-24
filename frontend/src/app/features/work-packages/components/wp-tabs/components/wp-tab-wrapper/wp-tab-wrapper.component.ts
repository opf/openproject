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

import { UIRouterGlobals } from '@uirouter/core';
import {
  Component,
  Input,
  OnInit,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { WpTabDefinition } from 'core-app/features/work-packages/components/wp-tabs/components/wp-tab-wrapper/tab';
import { WorkPackageTabsService } from 'core-app/features/work-packages/components/wp-tabs/services/wp-tabs/wp-tabs.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';

@Component({
  templateUrl: './wp-tab-wrapper.html',
  selector: 'op-wp-tab',
})
export class WpTabWrapperComponent implements OnInit {
  @Input() public workPackageId:string;
  @Input() public tabIdentifier:string;

  workPackage:WorkPackageResource;

  ndcDynamicInputs$:Observable<{
    workPackage:WorkPackageResource;
    tab:WpTabDefinition | undefined;
  }>;

  constructor(
    readonly I18n:I18nService,
    readonly uiRouterGlobals:UIRouterGlobals,
    readonly apiV3Service:ApiV3Service,
    readonly wpTabsService:WorkPackageTabsService,
  ) {}

  ngOnInit() {
    const { workPackageId } = this.uiRouterGlobals.params as unknown as { workPackageId:string };
    const { tabIdentifier } = this.uiRouterGlobals.params as unknown as { tabIdentifier:string };
    this.workPackageId = (workPackageId || this.workPackageId);
    this.tabIdentifier = (tabIdentifier || this.tabIdentifier);

    this.ndcDynamicInputs$ = this
      .apiV3Service
      .work_packages
      .id(this.workPackageId)
      .requireAndStream()
      .pipe(
        map((wp) => ({
          workPackage: wp,
          tab: this.findTab(wp),
        })),
      );
  }

  findTab(workPackage:WorkPackageResource):WpTabDefinition | undefined {
    return this.wpTabsService.getTab(this.tabIdentifier, workPackage);
  }
}
