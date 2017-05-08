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

angular.module('openproject.uiComponents')
  .directive('accessibleByKeyboard', [require(
    './accessible-by-keyboard-directive')])
  .directive('accessibleCheckbox', [require('./accessible-checkbox-directive')])
  .directive('accessibleElement', [require('./accessible-element-directive')])
  .directive('authoring', ['I18n', 'PathHelper', 'TimezoneService', require(
    './authoring-directive')])
  .directive('copyToClipboard', [
    'I18n',
    '$timeout',
    'NotificationsService',
    'ConfigurationService',
    require('./copy-to-clipboard-directive')
  ])
  .directive('opDate', ['TimezoneService', require('./date/date-directive')])
  .directive('opTime', ['TimezoneService', require('./date/time-directive')])
  .directive('opDateTime', ['$compile', 'TimezoneService', require('./date/date-time-directive')])
  .directive('emptyElement', [require('./empty-element-directive')])
  .constant('ENTER_KEY', 13)
  .directive('expandableSearch', ['ENTER_KEY', require('./expandable-search')])
  .directive('focus', [
    'FocusHelper',
    require('./focus-directive')
  ])
  .constant('FOCUSABLE_SELECTOR', 'a, button, :input, [tabindex], select')
  .service('FocusHelper', ['$timeout', 'FOCUSABLE_SELECTOR', require(
    './focus-helper')])
  .service('I18n', [require('./i18n')])
  .directive('inaccessibleByTab', [require('./inaccessible-by-tab-directive')])
  .directive('modal', [require('./modal-directive')])
  .directive('modalLoading', ['I18n', require('./modal-loading-directive')])
  .directive('persistentToggle', [
    '$timeout',
    'CacheService',
    require('./persistent-toggle-directive')]
  )
  .constant('LABEL_MAX_CHARS', 40)
  .constant('KEY_CODES', {
    enter: 13,
    up: 38,
    down: 40
  })
  .directive('selectableTitle', [require('./selectable-title-directive')])
  .constant('DOUBLE_CLICK_DELAY', 300)
  // Thanks to http://stackoverflow.com/a/20445344
  .directive('singleClick', [
    'DOUBLE_CLICK_DELAY',
    '$parse',
    '$timeout',
    require('./single-click')
  ])
  .directive('slideToggle', [require('./slide-toggle')])
  .directive('sortLink', ['I18n', 'SortService', require(
    './sort-link-directive')])
  .constant('ESC_KEY', 27)
  .directive('userField', ['PathHelper', require('./user-field-directive')])
  .directive('wikiToolbar', [require('./wiki-toolbar-directive')])
  .directive('zoomSlider', ['I18n', require('./zoom-slider-directive')])
  .directive('clickNotification', ['$timeout','NotificationsService', require('./click-notification-directive')])
  .directive('notifications', [require('./notifications-directive')])
  .directive('uploadProgress', [require('./upload-progress-directive')])
  .directive('attachmentIcon', [require('./attachment-icon-directive')])
  .filter('ancestorsExpanded', require('./filters/ancestors-expanded-filter'))
  .directive('highlightCol', [require('./highlight-col-directive')])
  .directive('confirmPopup', ['$window', require('./confirm-popup-directive')])
  .directive('clickOnKeypress', [require('./click-on-keypress-directive')]);
