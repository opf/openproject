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
  Input,
  ViewEncapsulation,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';

@Component({
  templateUrl: './baseline-legends.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'op-baseline-legends',
  encapsulation: ViewEncapsulation.None,
})
export class OpBaselineLegendsComponent {
  @Input() date:string;

  @Input() time:string;

  @Input() filter:string;

  @Input() numAdded:number;

  @Input() numRemoved:number;

  @Input() numUpdated:number;

  public text = {
    time_description: () => this.I18n.t('js.baseline.legends.changes_since', { filter: this.filter, date: this.date, time: this.time }),
    now_meets_filter_criteria: () => this.I18n.t('js.baseline.legends.changes_since', { new: this.numAdded }),
    no_longer_meets_filter_criteria: () => this.I18n.t('js.baseline.legends.changes_since', { removed: this.numRemoved }),
    maintained_with_changes: () => this.I18n.t('js.baseline.legends.changes_since', { updated: this.numUpdated }),
  };

  constructor(
    readonly I18n:I18nService,
  ) {}
}
