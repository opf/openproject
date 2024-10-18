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
  ElementRef,
  EventEmitter,
  HostBinding,
  Input,
  OnInit,
  Output,
} from '@angular/core';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import SpotDropAlignmentOption from 'core-app/spot/drop-alignment-options';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { DayResourceService } from 'core-app/core/state/days/day.service';
import { IDay } from 'core-app/core/state/days/day.model';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { Observable } from 'rxjs';
import {
  DEFAULT_TIMESTAMP,
  WorkPackageViewBaselineService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { validDate } from 'core-app/shared/components/datepicker/helpers/date-modal.helpers';
import {
  baselineFilterFromValue,
  getPartsFromTimestamp,
  offsetToUtcString,
} from 'core-app/features/work-packages/components/wp-baseline/baseline-helpers';
import * as moment from 'moment-timezone';
import { BannersService } from 'core-app/core/enterprise/banners.service';
import { enterpriseDocsUrl } from 'core-app/core/setup/globals/constants.const';
import { DayElement } from 'flatpickr/dist/types/instance';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';
import { WorkPackageIsolatedQuerySpaceDirective } from 'core-app/features/work-packages/directives/query-space/wp-isolated-query-space.directive';


@Component({
  hostDirectives: [WorkPackageIsolatedQuerySpaceDirective],
  template: `
    <op-baseline
      [visible]="visible"
      [showActionBar]="showActionBar"
      [showHeaderText]="showHeaderText"
    ></op-baseline>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OpBaselineEntryComponent {
  @Input() showActionBar? = false;
  @Input() visible = true;
  @Input() showHeaderText = true;

  constructor(
    readonly elementRef:ElementRef,
  ) {
    populateInputsFromDataset(this);
  }
}
