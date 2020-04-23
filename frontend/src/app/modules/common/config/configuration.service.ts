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

import {Injectable} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {ConfigurationDmService} from "core-app/modules/hal/dm-services/configuration-dm.service";
import {ConfigurationResource} from "core-app/modules/hal/resources/configuration-resource";
import * as moment from "moment";

@Injectable({ providedIn: 'root' })
export class ConfigurationService {
  // fetches configuration from the ApiV3 endpoint
  // TODO: this currently saves the request between page reloads,
  // but could easily be stored in localStorage
  private configuration:ConfigurationResource;
  public initialized:Promise<Boolean>;

  public constructor(readonly I18n:I18nService,
                     readonly configurationDm:ConfigurationDmService) {
    this.initialized = this.loadConfiguration().then(() => true).catch(() => false);
  }

  public commentsSortedInDescendingOrder() {
    return this.userPreference('commentSortDescending');
  }

  public warnOnLeavingUnsaved() {
    return this.userPreference('warnOnLeavingUnsaved');
  }

  public autoHidePopups() {
    return this.userPreference('autoHidePopups');
  }

  public isTimezoneSet()  {
    return !!this.timezone();
  }

  public timezone()  {
    return this.userPreference('timeZone');
  }

  public get maximumAttachmentFileSize() {
    return this.systemPreference('maximumAttachmentFileSize');
  }

  public get perPageOptions() {
    return this.systemPreference('perPageOptions');
  }

  public dateFormatPresent()  {
    return !!this.systemPreference('dateFormat');
  }

  public dateFormat()  {
    return this.systemPreference('dateFormat');
  }

  public timeFormatPresent()  {
    return !!this.systemPreference('timeFormat');
  }

  public timeFormat()  {
    return this.systemPreference('timeFormat');
  }

  public startOfWeekPresent()  {
    return !!this.systemPreference('startOfWeek');
  }

  public startOfWeek()  {
    if (this.startOfWeekPresent()) {
      return this.systemPreference('startOfWeek');
    } else {
      return moment.localeData(I18n.locale).firstDayOfWeek();
    }
  }

  private loadConfiguration() {
    return this.configurationDm.load().toPromise().then((configuration) => {
      this.configuration = configuration;
    });
  }

  private userPreference(pref:string) {
    return _.get(this.configuration, ['userPreferences', pref]);
  }

  private systemPreference(pref:string) {
    return _.get(this.configuration, pref);
  }
}
