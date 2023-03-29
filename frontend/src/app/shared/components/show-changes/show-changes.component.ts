// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2023 the OpenProject GmbH
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
  Component,
  HostBinding,
} from '@angular/core';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { WorkPackageViewFiltersService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';

@Component({
  selector: 'op-show-changes',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './show-changes.component.html',
  styleUrls: ['./show-changes.component.sass'],
})
export class OpShowChangesComponent extends UntilDestroyedMixin {
  @HostBinding('class.op-show-changes') className = true;

  public text = {
    toggle_title: this.I18n.t('js.show_changes.toggle_title'),
    header_description: this.I18n.t('js.show_changes.header_description'),
    clear: this.I18n.t('js.show_changes.clear'),
    apply: this.I18n.t('js.show_changes.apply'),
    show_changes_since: this.I18n.t('js.show_changes.show_changes_since'),
    time: this.I18n.t('js.show_changes.time'),
  };

  public opened = false;

  public filterSelected = false;

  public showChangesAvailableValues = [
    {
      value: '0',
      title: this.I18n.t('js.show_changes.drop_down.none'),
    },
    {
      value: '1',
      title: this.I18n.t('js.show_changes.drop_down.yesterday'),
    },
    {
      value: '2',
      title: this.I18n.t('js.show_changes.drop_down.last_working_day'),
    },
    {
      value: '3',
      title: this.I18n.t('js.show_changes.drop_down.last_week'),
    },
    {
      value: '4',
      title: this.I18n.t('js.show_changes.drop_down.last_month'),
    },
    {
      value: '5',
      title: this.I18n.t('js.show_changes.drop_down.a_specific_date'),
    },
    {
      value: '6',
      title: this.I18n.t('js.show_changes.drop_down.between_two_specific_dates'),
    },
  ];

  public query$ = this.wpTableFilters.querySpace.query.values$();

  constructor(
    readonly I18n:I18nService,
    readonly wpTableFilters:WorkPackageViewFiltersService,
    readonly halResourceService:HalResourceService,
  ) {
    super();
  }

  public toggleOpen():void {
    this.opened = !this.opened;
  }

  public clearSelection():void {
  }

  public onSubmit(e:Event):void {
    e.preventDefault();

    this.close();
  }

  public close():void {
    this.opened = false;
  }

  public valueSelected(value:string):void {
    if (value !== '0') {
      this.filterSelected = true;
    } else {
      this.filterSelected = false;
    }
  }
}
