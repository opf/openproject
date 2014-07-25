//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
//++

angular.module('openproject.config')

.service('ConfigurationService', [
  '$log',
  function($log) {

  return {
    settingsPresent: function() {
      return gon && gon.settings;
    },
    userPreferencesPresent: function() {
      return this.settingsPresent() && gon.settings.hasOwnProperty('user_preferences');
    },
    displaySettingsPresent: function() {
      return this.settingsPresent() && gon.settings.hasOwnProperty('display');
    },
    displaySettingPresent: function(setting) {
      return this.displaySettingsPresent()
        && gon.settings.display.hasOwnProperty(setting)
        && gon.settings.display[setting] != false;
    },
    accessibilityModeEnabled: function() {
      if (!this.userPreferencesPresent()) {
        $log.error('User preferences are not available.');
        return false;
      } else {
        return gon.settings.user_preferences.impaired;
      }
    },
    commentsSortedInDescendingOrder: function() {
      if (!this.userPreferencesPresent()) {
        $log.error('User preferences are not available.');
        return false;
      } else {
        return gon.settings.user_preferences.others.comments_sorting === 'desc';
      }
    },
    isTimezoneSet: function() {
      return this.userPreferencesPresent() && gon.settings.user_preferences.time_zone != '';
    },
    timezone: function() {
      return (this.isTimezoneSet()) ? gon.settings.user_preferences.time_zone : '';
    },
    dateFormatPresent: function() {
      return this.displaySettingPresent('date_format');
    },
    dateFormat: function() {
      return gon.settings.display.date_format;
    },
    timeFormatPresent: function() {
      return this.displaySettingPresent('time_format');
    },
    timeFormat: function() {
      return gon.settings.display.time_format;
    }
  };
}]);
