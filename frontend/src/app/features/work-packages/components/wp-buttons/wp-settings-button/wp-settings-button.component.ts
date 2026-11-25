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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ChangeDetectionStrategy, Component, Input, computed, inject, input } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { map } from 'rxjs/operators';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';

@Component({
  templateUrl: './wp-settings-button.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class WorkPackageSettingsButtonComponent {
  readonly I18n = inject(I18nService);

  private readonly urlParams = inject(UrlParamsService);

  @Input() hideTableOptions = false;

  @Input() showCalendarSharingOption = false;

  readonly listShortcuts = input(false);

  private readonly detailsOpen = toSignal(
    this.urlParams.changed$.pipe(map(() => this.urlParams.currentDetailsRouteParams() !== null)),
    { initialValue: this.urlParams.currentDetailsRouteParams() !== null },
  );

  protected readonly accessKey = computed(() => (this.listShortcuts() && !this.detailsOpen() ? 7 : null));

  public text = {
    more_actions: this.I18n.t('js.button_more_actions'),
  };
}
