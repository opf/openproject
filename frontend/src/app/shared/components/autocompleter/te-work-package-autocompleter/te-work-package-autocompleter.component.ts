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
  AfterViewInit,
  Component,
  EventEmitter,
  Injector,
  Output,
  ViewEncapsulation,
} from '@angular/core';
import { WorkPackageAutocompleterComponent } from 'core-app/shared/components/autocompleter/work-package-autocompleter/wp-autocompleter.component';

export type TimeEntryWorkPackageAutocompleterMode = 'all'|'recent';

@Component({
  templateUrl: './te-work-package-autocompleter.component.html',
  styleUrls: [
    './te-work-package-autocompleter.component.sass',
  ],
  selector: 'te-work-package-autocompleter',
  encapsulation: ViewEncapsulation.None,
})
export class TimeEntryWorkPackageAutocompleterComponent extends WorkPackageAutocompleterComponent implements AfterViewInit {
  @Output() modeSwitch = new EventEmitter<TimeEntryWorkPackageAutocompleterMode>();

  constructor(
    readonly injector:Injector,
  ) {
    super(injector);

    this.text.all = this.I18n.t('js.label_all');
    this.text.recent = this.I18n.t('js.label_recent');
  }

  public mode:TimeEntryWorkPackageAutocompleterMode = 'all';

  public setMode(value:TimeEntryWorkPackageAutocompleterMode) {
    if (value !== this.mode) {
      this.modeSwitch.emit(value);
    }
    this.mode = value;
  }
}
