// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2022 the OpenProject GmbH
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
  Injector,
  Input,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { DatepickerModalService } from 'core-app/shared/components/datepicker/datepicker.modal.service';
import {
  map,
  take,
} from 'rxjs/operators';
import { StateService } from '@uirouter/core';

@Component({
  selector: 'op-datepicker-banner',
  templateUrl: './datepicker-banner.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class DatepickerBannerComponent {
  @Input() scheduleManually = false;

  hasRelations$ = this.datepickerService.hasRelations$;

  hasPrecedingRelations$ = this
    .datepickerService
    .precedingWorkPackages$
    .pipe(
      map((relations) => relations?.length > 0),
    );

  hasFollowingRelations$ = this
    .datepickerService
    .followingWorkPackages$
    .pipe(
      map((relations) => relations?.length > 0),
    );

  isParent = this.datepickerService.isParent;

  text = {
    automatically_scheduled_parent: this.I18n.t('js.work_packages.datepicker_modal.automatically_scheduled_parent'),
    manually_scheduled: this.I18n.t('js.work_packages.datepicker_modal.manually_scheduled'),
    start_date_limited_by_relations: this.I18n.t('js.work_packages.datepicker_modal.start_date_limited_by_relations'),
    changing_dates_affects_follow_relations: this.I18n.t('js.work_packages.datepicker_modal.changing_dates_affects_follow_relations'),
    click_on_show_relations_to_open_gantt: this.I18n.t(
      'js.work_packages.datepicker_modal.click_on_show_relations_to_open_gantt',
      { button_name: this.I18n.t('js.work_packages.datepicker_modal.show_relations') },
    ),
    show_relations_button: this.I18n.t('js.work_packages.datepicker_modal.show_relations'),
  };

  constructor(
    readonly datepickerService:DatepickerModalService,
    readonly injector:Injector,
    readonly I18n:I18nService,
    readonly state:StateService,
  ) {}

  openGantt(evt:MouseEvent):void {
    evt.preventDefault();

    this
      .datepickerService
      .getInvolvedWorkPackageIds()
      .pipe(
        take(1),
      )
      .subscribe((ids) => {
        const props = {
          c: ['id', 'subject', 'type', 'status', 'assignee', 'createdAt'],
          t: 'createdAt:desc',
          tv: true,
          f: [{ n: 'id', o: '=', v: ids }],
        };

        const href = this.state.href(
          'work-packages.partitioned.list',
          {
            query_id: null,
            projects: null,
            projectPath: null,
            query_props: JSON.stringify(props),
          },
        );
        window.open(href, '_blank');
      });
  }
}
