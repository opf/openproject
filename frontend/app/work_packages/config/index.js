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

/* jshint camelcase: false */

angular.module('openproject.workPackages.config')

.constant('INITIALLY_SELECTED_COLUMNS', [{ name: 'id' }, { name: 'project' }, { name: 'type' }, { name: 'status' }, { name: 'priority' }, { name: 'subject' }, { name: 'assigned_to_id' }, { name: 'updated_at' }])

.constant('OPERATORS_AND_LABELS_BY_FILTER_TYPE', {
  list: [['=', 'label_equals'], ['!', 'label_not_equals']],
  list_model: [['=', 'label_equals'], ['!', 'label_not_equals']],
  list_status: [['o', 'label_open_work_packages'], ['=', 'label_equals'], ['!', 'label_not_equals'], ['c', 'label_closed_work_packages'], ['*', 'label_all']],
  list_optional: [['=', 'label_equals'], ['!', 'label_not_equals'], ['!*', 'label_none'], ['*', 'label_all']],
  list_subprojects: [['*', 'label_all'], ['!*', 'label_none'], ['=', 'label_equals']],
  date: [['<t+', 'label_in_less_than'], ['>t+', 'label_in_more_than'], ['t+', 'label_in'], ['t', 'label_today'], ['w', 'label_this_week'], ['>t-', 'label_less_than_ago'], ['<t-', 'label_more_than_ago'], ['t-', 'label_ago']],
  date_past: [['>t-', 'label_less_than_ago'], ['<t-', 'label_more_than_ago'], ['t-', 'label_ago'], ['t', 'label_today'], ['w', 'label_this_week']],
  string: [['=', 'label_equals'], ['~', 'label_contains'], ['!', 'label_not_equals'], ['!~', 'label_not_contains']],
  text: [['~', 'label_contains'], ['!~', 'label_not_contains']],
  integer: [['=', 'label_equals'], ['>=', 'label_greater_or_equal'], ['<=', 'label_less_or_equal'], ['!*', 'label_none'], ['*', 'label_all']]
})

.constant('AVAILABLE_WORK_PACKAGE_FILTERS', {
  status_id: { type: 'list_status', modelName: 'status' , order: 1, locale_name: 'status' },
  type_id: { type: 'list_model', modelName: 'type', order: 2, locale_name: 'type' },
  priority_id: { type: 'list_model', modelName: 'priority', order: 3, locale_name: 'priority'},
  assigned_to_id: { type: 'list_optional', modelName: 'user' , order: 4, locale_name: 'assigned_to' },
  author_id: { type: 'list_model', modelName: 'user' , order: 5, locale_name: 'author' },
  watcher_id: {type: 'list_model', modelName: 'user', order: 6, locale_name: 'watcher'},
  responsible_id: {type: 'list_optional', modelName: 'user', order: 6, locale_name: 'responsible'},
  fixed_version_id: {type: 'list_optional', modelName: 'version', order: 7, locale_name: 'fixed_version'},
  category_id: { type: 'list_optional', modelName: 'category', order: 7, locale_name: 'category' },
  member_of_group: {type: 'list_optional', modelName: 'group', order: 8, locale_name: 'member_of_group'},
  assigned_to_role: {type: 'list_optional', modelName: 'role', order: 9, locale_name: 'assigned_to_role'},
  subject: { type: 'text', order: 10, locale_name: 'subject' },
  created_at: { type: 'date_past', order: 11, locale_name: 'created_at' },
  updated_at: { type: 'date_past', order: 12, locale_name: 'updated_at' },
  start_date: { type: 'date', order: 13, locale_name: 'start_date' },
  due_date: { type: 'date', order: 14, locale_name: 'due_date' },
  estimated_hours: { type: 'integer', order: 15, locale_name: 'estimated_hours' },
  done_ratio: { type: 'integer', order: 16, locale_name: 'done_ratio' },
  project_id: { type: 'list_model', modelName: 'project', order: 17, locale_name: 'project' },
  subproject_id: { type: 'list_subprojects', modelName: 'sub_project', order: 18, locale_name: 'subproject' }
})

.constant('DEFAULT_SORT_CRITERIA', 'parent:desc')

.constant('MAX_SORT_ELEMENTS', 3)

.constant('DEFAULT_PAGINATION_OPTIONS', {
  page: 1,
  perPage: 10,
  perPageOptions: [10, 100, 500, 1000],
  maxVisiblePageOptions: 6,
  optionsTruncationSize: 2
});
