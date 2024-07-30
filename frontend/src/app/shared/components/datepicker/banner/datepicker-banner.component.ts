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
  Component,
  Injector,
  Input,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  map,
  take,
} from 'rxjs/operators';
import { StateService } from '@uirouter/core';
import { DateModalRelationsService } from 'core-app/shared/components/datepicker/services/date-modal-relations.service';

@Component({
  selector: 'op-datepicker-banner',
  templateUrl: './datepicker-banner.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OpDatePickerBannerComponent {
  @Input() scheduleManually = false;

  hasRelations$ = this.dateModalRelations.hasRelations$;

  hasPrecedingRelations$ = this
    .dateModalRelations
    .precedingWorkPackages$
    .pipe(
      map((relations) => relations?.length > 0),
    );

  hasFollowingRelations$ = this
    .dateModalRelations
    .followingWorkPackages$
    .pipe(
      map((relations) => relations?.length > 0),
    );

  get isParent() {
    return this.dateModalRelations.isParent;
  }

  get isChild() {
    return this.dateModalRelations.isChild;
  }

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
    readonly dateModalRelations:DateModalRelationsService,
    readonly injector:Injector,
    readonly I18n:I18nService,
    readonly state:StateService,
  ) {}

  openGantt(evt:MouseEvent):void {
    evt.preventDefault();

    this
      .dateModalRelations
      .getInvolvedWorkPackageIds()
      .pipe(
        take(1),
      )
      .subscribe((ids) => {
        const props = {
          c: ['id', 'subject', 'type', 'status', 'assignee', 'project', 'startDate', 'dueDate'],
          t: 'id:asc',
          tv: true,
          hi: true,
          f: [{ n: 'id', o: '=', v: ids }],
        };

        const href = this.state.href(
          'gantt.partitioned.list',
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
