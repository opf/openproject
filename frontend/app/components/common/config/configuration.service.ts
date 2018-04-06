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

import {opConfigModule} from '../../../angular-modules';
import {PathHelperService} from 'core-components/common/path-helper/path-helper.service';

export class ConfigurationService {
  // fetches configuration from the ApiV3 endpoint
  // TODO: this currently saves the request between page reloads,
  // but could easily be stored in localStorage
  private cache:any;
  private path:string = this.PathHelper.apiConfigurationPath();
  public settings = this.initSettings();

  public constructor(private $q:ng.IQService,
                     private $http:ng.IHttpService,
                     private $window:ng.IWindowService,
                     private PathHelper:PathHelperService,
                     private I18n:op.I18n) {

  }

  public fetchSettings () {
    var data = this.$q.defer();
    let resolve = this.$http.get(this.path) as any;
    resolve.success(function (settings:any) {
      data.resolve(settings);
    }).error(function (err:any) {
      data.reject(err);
    });
    return data.promise;
  }

  public api() {
    var settings = this.$q.defer();
    if (this.cache) {
      settings.resolve(this.cache);
    } else {
      this.fetchSettings().then((data:any) => {
        this.cache = data;
        settings.resolve(data);
      });
    }
    return settings.promise;
  }

  public initSettings() {

    var settings:any = {},
      defaults:any = {
        enabled_modules: [],
        display: {},
        user_preferences: {
          impaired: false,
          time_zone: '',
          others: {
            comments_sorting: 'asc',
            warn_on_leaving_unsaved: true,
            auto_hide_popups: false
          }
        }
      };

    var gon = (window as any).gon;
    if (gon !== undefined) {
      settings = gon.settings;
    }

    return _.merge(defaults, settings);
  }

  public displaySettingPresent(setting:any) {
    return this.settings.display.hasOwnProperty(setting) &&
      this.settings.display[setting] !== false;
  }

  public accessibilityModeEnabled() {
    return this.settings.user_preferences.impaired;
  }
  public commentsSortedInDescendingOrder() {
    return this.settings.user_preferences.others.comments_sorting === 'desc';
  }

  public warnOnLeavingUnsaved() {
    return this.settings.user_preferences.others.warn_on_leaving_unsaved === true;
  }

  public autoHidePopups() {
    return this.settings.user_preferences.others.auto_hide_popups === true;
  }

  public isTimezoneSet()  {
    return this.settings.user_preferences.time_zone !== '';
  }

  public timezone()  {
    return this.settings.user_preferences.time_zone;
  }

  public dateFormatPresent()  {
    return this.displaySettingPresent('date_format') &&
      this.settings.display.date_format !== '';
  }

  public textFormat() {
    return this.settings.display.text_format;
  }

  public dateFormat()  {
    return this.settings.display.date_format;
  }

  public timeFormatPresent()  {
    return this.displaySettingPresent('time_format') &&
      this.settings.display.time_format !== '';
  }

  public timeFormat()  {
    return this.settings.display.time_format;
  }

  public isModuleEnabled(module:string) {
    return this.settings.enabled_modules.indexOf(module) >= 0;
  }

  public startOfWeekPresent()  {
    return this.displaySettingPresent('start_of_week') &&
      this.settings.display.start_of_week !== '';
  }

  public startOfWeek()  {
    if (this.startOfWeekPresent()) {
      return this.settings.display.start_of_week;
    }

    // This if/else statement is used because
    // jquery regionals have different start day for German locale
    if (I18n.locale === 'en') {
      return 1;
    } else if (I18n.locale === 'de') {
      return 0;
    }

    return '';
  }
}

opConfigModule.service('ConfigurationService', ConfigurationService);
