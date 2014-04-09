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

angular.module('openproject.workPackages.config')

.constant('INITIALLY_SELECTED_COLUMNS', ['id', 'project', 'type', 'status', 'priority', 'subject', 'assigned_to_id', 'updated_at'])

.constant('OPERATORS_AND_LABELS_BY_FILTER_TYPE', {
  list: {'=':'label_equals','!':'label_not_equals'},
  list_model: {'=':'label_equals','!':'label_not_equals'},
  list_status: {'o':'label_open_work_packages','=':'label_equals','!':'label_not_equals','c':'label_closed_work_packages','*':'label_all'},
  list_optional: {'=':'label_equals','!':'label_not_equals','!*':'label_none','*':'label_all'},
  list_subprojects: {'*':'label_all','!*':'label_none','=':'label_equals'},
  date: {'<t+':'label_in_less_than','>t+':'label_in_more_than','t+':'label_in','t':'label_today','w':'label_this_week','>t-':'label_less_than_ago','<t-':'label_more_than_ago','t-':'label_ago'},
  date_past: {'>t-':'label_less_than_ago','<t-':'label_more_than_ago','t-':'label_ago','t':'label_today','w':'label_this_week'},
  string: {'=':'label_equals','~':'label_contains','!':'label_not_equals','!~':"label_not_contains"},
  text: {'~':'label_contains','!~':"label_not_contains"},
  integer: {'=':'label_equals','>=':'label_greater_or_equal','<=':'label_less_or_equal','!*':'label_none','*':'label_all'}
})

.constant('AVAILABLE_WORK_PACKAGE_FILTERS', {
  status_id: { type: 'list_status', modelName: 'status' , order: 1, name: 'Status' },
  type_id: { type: 'list_model', modelName: 'type', order: 2, name: 'Type' },
  priority_id: { type: 'list_model', modelName: 'priority', order: 3, name: 'Priority'},
  assigned_to_id: { type: 'list_model', modelName: 'user' , order: 4, name: 'Assigned to' },
  author_id: { type: 'list_model', modelName: 'user' , order: 5, name: 'Author' },
  responsible_id: {type: 'list_model', modelName: 'user', order: 6, name: 'Watcher'},
  fixed_version_id: {type: 'list_model', modelName: 'version', order: 7, name: 'Version'},
  member_of_group: {type: 'list_model', modelName: 'group', order: 8, name: 'Assignee\'s group'},
  assigned_to_role: {type: 'list_model', modelName: 'role', order: 9, name: 'Assignee\'s role'},
  subject: { type: 'text', order: 10, name: 'Subject' },
  created_at: { type: 'date_past', order: 11, name: 'Created on' },
  updated_at: { type: 'date_past', order: 12, name: 'Updated on' },
  start_date: { type: 'date', order: 13, name: 'Start date' },
  due_date: { type: 'date', order: 14, name: 'Due date' },
  estimated_hours: { type: 'integer', order: 15, name: 'Estimated time' },
  done_ratio: { type: 'integer', order: 16, name: '% done' },
  project_id: { type: 'list_model', modelName: 'project', order: 17, name: 'Project' },
  subproject_id: { type: 'list_model', modelName: 'sub_project', order: 18, name: 'Sub-project' },
})

.constant('DEFAULT_SORT_CRITERIA', 'parent:desc')

.constant('DEFAULT_PAGINATION_OPTIONS', {
  page: 1,
  perPage: 10,
  perPageOptions: [10, 20, 50, 100, 500, 1000],
  maxVisiblePageOptions: 9,
  optionsTruncationSize: 2,
});
