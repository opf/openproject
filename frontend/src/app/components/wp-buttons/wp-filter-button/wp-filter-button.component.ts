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

import {AbstractWorkPackageButtonComponent} from 'core-components/wp-buttons/wp-buttons.module';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit} from '@angular/core';
import {WorkPackageFiltersService} from 'core-components/filters/wp-filters/wp-filters.service';
import {WorkPackageViewFiltersService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-filters.service";
import {componentDestroyed} from "@w11k/ngx-componentdestroyed";

@Component({
  selector: 'wp-filter-button',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './wp-filter-button.html'
})
export class WorkPackageFilterButtonComponent extends AbstractWorkPackageButtonComponent implements OnInit {
  public count:number;
  public initialized:boolean = false;

  public buttonId:string = 'work-packages-filter-toggle-button';
  public iconClass:string = 'icon-filter';

  constructor(readonly I18n:I18nService,
              protected cdRef:ChangeDetectorRef,
              protected wpFiltersService:WorkPackageFiltersService,
              protected wpTableFilters:WorkPackageViewFiltersService) {
    super(I18n);
  }

  ngOnInit():void {
    this.setupObserver();
  }

  public get labelKey():string {
    return 'js.button_filter';
  }

  public get textKey():string {
    return 'js.toolbar.filter';
  }

  public get label():string {
    return this.prefix + this.text.label;
  }

  public get filterCount():number {
    return this.count;
  }

  public performAction(event:Event) {
    this.toggleVisibility();
  }

  public toggleVisibility() {
    this.wpFiltersService.toggleVisibility();
  }

  private setupObserver() {
    this.wpTableFilters
      .live$()
      .pipe(
        this.untilDestroyed()
      )
      .subscribe(() => {
        this.count = this.wpTableFilters.currentlyVisibleFilters.length;
        this.initialized = true;
        this.cdRef.detectChanges();
      });

    this.wpFiltersService
      .observeUntil(componentDestroyed(this))
      .subscribe(() => {
        this.isActive = this.wpFiltersService.visible;
        this.cdRef.detectChanges();
      });
  }
}
