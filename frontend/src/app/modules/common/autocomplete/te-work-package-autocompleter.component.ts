// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {
  AfterViewInit,
  Component,
 ViewEncapsulation,
 Output,
 EventEmitter,
 ChangeDetectorRef,
} from '@angular/core';
import {WorkPackageAutocompleterComponent} from "core-app/modules/common/autocomplete/wp-autocompleter.component";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";

export type TimeEntryWorkPackageAutocompleterMode = 'all'|'recent';

@Component({
  templateUrl: './te-work-package-autocompleter.component.html',
  styleUrls: ['./te-work-package-autocompleter.component.sass'],
  selector: 'te-work-package-autocompleter',
  encapsulation: ViewEncapsulation.None
})
export class TimeEntryWorkPackageAutocompleterComponent extends WorkPackageAutocompleterComponent implements AfterViewInit {
  @Output() modeSwitch = new EventEmitter<TimeEntryWorkPackageAutocompleterMode>();

  constructor(readonly I18n:I18nService,
              readonly cdRef:ChangeDetectorRef,
              readonly currentProject:CurrentProjectService,
              readonly pathHelper:PathHelperService) {
    super(I18n, cdRef, currentProject, pathHelper);

    this.text['all'] = this.I18n.t('js.label_all');
    this.text['recent'] = this.I18n.t('js.label_recent');
  }

  public loading:boolean = false;
  public mode:TimeEntryWorkPackageAutocompleterMode = 'all';

  public setMode(value:TimeEntryWorkPackageAutocompleterMode) {
    if (value !== this.mode) {
      this.modeSwitch.emit(value);
    }
    this.mode = value;
  }
}
