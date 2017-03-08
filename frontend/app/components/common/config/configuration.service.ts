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

function ConfigurationService(
  $q:ng.IQService,
  $http:ng.IHttpService,
  $window:ng.IWindowService,
  PathHelper:any,
  I18n:op.I18n) {
  // fetches configuration from the ApiV3 endpoint
  // TODO: this currently saves the request between page reloads,
  // but could easily be stored in localStorage
  var cache = false;
  var path:string = PathHelper.apiConfigurationPath();
  var fetchSettings = function () {
    var data = $q.defer();
    let resolve = $http.get(path) as any;
    resolve.success(function (settings:any) {
      data.resolve(settings);
    }).error(function (err:any) {
      data.reject(err);
    });
    return data.promise;
  };
  var api = function () {
    var settings = $q.defer();
    if (cache) {
      settings.resolve(cache);
    } else {
      fetchSettings().then(function (data:any) {
        cache = data;
        settings.resolve(data);
      });
    }
    return settings.promise;
  };
  var initSettings = function () {
    var settings:any = {},
      defaults:any = {
        enabled_modules: [],
        display: [],
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

    var gon = ($window as any).gon;
    if (gon !== undefined) {
      settings = gon.settings;
    }

    return _.merge(defaults, settings);
  };

  return {
    settings: initSettings(),
    api: api,
    displaySettingPresent: function (this:any, setting:any) {
      return this.settings.display.hasOwnProperty(setting) &&
        this.settings.display[setting] !== false;
    },
    accessibilityModeEnabled: function (this:any) {
      return this.settings.user_preferences.impaired;
    },
    commentsSortedInDescendingOrder: function (this:any) {
      return this.settings.user_preferences.others.comments_sorting === 'desc';
    },
    warnOnLeavingUnsaved: function (this:any) {
      return this.settings.user_preferences.others.warn_on_leaving_unsaved === true;
    },
    autoHidePopups: function (this:any) {
      return this.settings.user_preferences.others.auto_hide_popups === true;
    },
    isTimezoneSet: function (this:any) {
      return this.settings.user_preferences.time_zone !== '';
    },
    timezone: function (this:any) {
      return this.settings.user_preferences.time_zone;
    },
    dateFormatPresent: function (this:any) {
      return this.displaySettingPresent('date_format') &&
        this.settings.display.date_format !== '';
    },
    dateFormat: function (this:any) {
      return this.settings.display.date_format;
    },
    timeFormatPresent: function (this:any) {
      return this.displaySettingPresent('time_format') &&
        this.settings.display.time_format !== '';
    },
    timeFormat: function (this:any) {
      return this.settings.display.time_format;
    },
    isModuleEnabled: function (this:any, module:string) {
      return this.settings.enabled_modules.indexOf(module) >= 0;
    },
    startOfWeekPresent: function (this:any) {
      return this.displaySettingPresent('start_of_week') &&
        this.settings.display.start_of_week !== '';
    },
    startOfWeek: function (this:any) {
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
  };
}

opConfigModule.factory('ConfigurationService', ConfigurationService);
