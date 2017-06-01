//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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

// TODO move to UI components
module.exports = function(I18n, $timeout, NotificationsService, ConfigurationService) {
  return {
    restrict: 'A',
    replace: false,
    scope: { clipboardTarget: '@' },
    link: function(scope, elem) {
      var target = scope.clipboardTarget ? angular.element(scope.clipboardTarget) : elem;
      elem.addClass('copy-to-clipboard');

      elem.click(function(evt) {
        var supported = (document.queryCommandSupported && document.queryCommandSupported('copy')),
          addNotification = function(type, message) {
            var notification;

          $timeout(function() {
            notification = NotificationsService[type](message);
          }, 0);

          // Remove the notification some time later
          // but only when we're not in accessible mode
          if (!ConfigurationService.accessibilityModeEnabled()) {
            $timeout(function() {
              NotificationsService.remove(notification);
            }, 5000);
          }
        };

        evt.preventDefault();

        // At least select the input for the user
        // even when clipboard API not supported
        target.select().focus();

        if (supported) {

          try {
            // Copy it to the clipboard
            if (document.execCommand('copy')) {
              addNotification('addSuccess', I18n.t('js.clipboard.copied_successful'));
              return;
            }
          } catch (e) {
            console.log(
              'Your browser seems to support the clipboard API, but copying failed: ' + e
            );
          }
        }

        addNotification('addError', I18n.t('js.clipboard.browser_error'));
      });
    }
  };
};
