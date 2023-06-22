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

import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  HostBinding,
  Input,
  OnInit,
  ViewEncapsulation,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { TimeEntryCreateService } from 'core-app/shared/components/time_entries/create/create.service';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import {
  filter,
  map,
  shareReplay,
  switchMap,
} from 'rxjs/operators';
import {
  from,
  Observable,
  of,
  timer,
} from 'rxjs';
import { TimeEntryResource } from 'core-app/features/hal/resources/time-entry-resource';
import { TimeEntryChangeset } from 'core-app/features/work-packages/helpers/time-entries/time-entry-changeset';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import * as moment from 'moment';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { TimeEntryEditService } from 'core-app/shared/components/time_entries/edit/edit.service';

export function pad(val:number):string {
  return val > 9 ? val.toString() : "0" + val.toString();
}

@Component({
  selector: 'op-wp-timer-button',
  templateUrl: './wp-timer-button.component.html',
  styleUrls: ['./wp-timer-button.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
})
export class WorkPackageTimerButtonComponent extends UntilDestroyedMixin implements OnInit {
  @HostBinding('class.op-wp-timer-button') className = true;

  @Input() public workPackage:WorkPackageResource;

  active:TimeEntryResource|null|undefined;

  elapsed$:Observable<string> = timer(0, 1000)
    .pipe(
      map(() => this.active),
      filter((timeEntry) => timeEntry !== null),
      map((timeEntry:TimeEntryResource) => {
        const start = moment(timeEntry.createdAt as string);
        const now = moment();
        const offset = moment(now).diff(start, 'seconds');

        const seconds = pad(offset % 60);
        const minutes = pad(parseInt((offset / 60).toString(), 10) % 60);
        const hours = pad(parseInt((offset / 3600).toString(), 10));

        return `${hours}:${minutes}:${seconds}`;
      }),
    );

  text = {
    workPackage: this.I18n.t('js.label_work_package'),
  }

  constructor(
    readonly I18n:I18nService,
    readonly apiV3Service:ApiV3Service,
    readonly timeEntryCreateService:TimeEntryCreateService,
    readonly timeEntryEditService:TimeEntryEditService,
    readonly halEditing:HalResourceEditingService,
    readonly schemaCache:SchemaCacheService,
    readonly timezoneService:TimezoneService,
    readonly cdRef:ChangeDetectorRef,
  ) {
    super();
  }

  ngOnInit() {
    this.reload();
  }

  reload():void {
    const filters = new ApiV3FilterBuilder();
    filters.add('ongoing', '=', true);

    this
      .apiV3Service
      .time_entries
      .filtered(filters)
      .get()
      .pipe(
        map((collection) => collection.elements.pop() || null),
      )
      .subscribe((timeEntry) => {
        this.active = timeEntry;
        this.cdRef.detectChanges();
      });
  }

  get activeForWorkPackage():boolean {
    return !!this.active && this.active.workPackage.href === this.workPackage.href;
  }

  clear():void {
    this.active = null;
    this.cdRef.detectChanges();
  }

  async stop(edit = true):Promise<unknown> {
    const active = this.active;
    if (!active) {
      return;
    }

    await this.schemaCache.ensureLoaded(active);

    const change = new TimeEntryChangeset(active);
    const hours = moment().diff(moment(active.createdAt), 'hours', true);
    const formatted = this.timezoneService.toISODuration(hours, 'hours');
    change.setValue('hours', formatted);
    change.setValue('ongoing', false);

    // eslint-disable-next-line consistent-return
    return this
      .halEditing
      .save(change)
      .then((commit) => {
        this.clear();
        if (edit) {
          return this.timeEntryEditService.edit(commit.resource as TimeEntryResource);
        }

        return undefined;
      });
  }

  async start():Promise<void> {
    if (this.active) {
      await this.stop(false);
    }

    this.timeEntryCreateService
      .createNewTimeEntry(moment(), this.workPackage, true)
      .pipe(
        switchMap((changeset) => from(this.halEditing.save(changeset))),
        map((result) => result.resource as TimeEntryResource),
      )
      .subscribe((active) => {
        this.active = active;
        this.cdRef.detectChanges();
      });
  }
}
