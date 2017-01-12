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

module.exports = function($timeout, CacheService) {
  return {
    restrict: 'EA',
    link: function(scope, element, attributes) {
      var clickHandler = element.find('.persistent-toggle--click-handler'),
          targetNotification = element.find('.persistent-toggle--notification'),
          cache = CacheService.localStorage();

      scope.isHidden = cache.get(attributes.identifier);

      function toggle(isNowHidden) {
        cache.put(attributes.identifier, isNowHidden);

        scope.$apply(function() {
          scope.isHidden = isNowHidden;
        });

        if (isNowHidden) {
          targetNotification.slideUp(function() {
            // Set hidden only after animation completed
            targetNotification.prop('hidden', true);
          });
        } else {
          targetNotification.slideDown();
          targetNotification.prop('hidden', false);
        }
      }

      // Clicking the handler toggles the notification
      clickHandler.bind('click', function() {
        toggle(!scope.isHidden);
      });

      // Closing the notification remembers the decision
      targetNotification.find('.notification-box--close').bind('click', function() {
        toggle(true);
      });

      // Set initial state
      targetNotification.prop('hidden', !!scope.isHidden);
    }
  };
};
