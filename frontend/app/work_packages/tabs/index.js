//-- copyright
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
//++

angular.module('openproject.workPackages.tabs')
  .directive('addWorkPackageChild', require(
    './add-work-package-child-directive'))
  .directive('addWorkPackageRelation', require(
    './add-work-package-relation-directive'))
  .directive('exclusiveEdit', require('./exclusive-edit-directive'))
  .directive('panelExpander', require('./panel-expander-directive'))
  .directive('relatedWorkPackageTableRow', [
    'I18n',
    'PathHelper',
    'WorkPackagesHelper', require(
      './related-work-package-table-row-directive')
  ])
  .directive('userActivity', [
    '$uiViewScroll',
    '$timeout',
    '$location',
    '$sce',
    'I18n',
    'PathHelper',
    'ActivityService',
    'UsersHelper',
    'ConfigurationService',
    'AutoCompleteHelper',
    require('./user-activity-directive')
  ])
  .directive('workPackageRelations', [
    'I18n',
    'WorkPackagesHelper',
    '$timeout',
    require('./work-package-relations-directive')
  ]);

// FIXME: move modules or files to the right place
angular.module('openproject.workPackages.directives')
  .directive('attachmentFileSize', require('./attachment-file-size-directive'))
  .directive('attachmentTitleCell', ['PathHelper', require(
    './attachment-title-cell-directive')])
  .directive('attachmentUserCell', ['PathHelper', require(
    './attachment-user-cell-directive')])
  .directive('attachmentsTable', ['I18n', require(
    './attachments-table-directive')])
  .directive('attachmentsTitle', require('./attachments-title-directive'))
  .directive('editableComment', require('./editable-comment-directive'));
