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

/* jshint camelcase: false */

// shared operator defs
const OP_NONE = {symbol:'!*', label:'label_none'};
const OP_ALL = {symbol:'*', label:'label_all'};
const OP_SEL_EQ = {symbol:'=', label:'label_equals'};
const OP_SEL_NEQ = {symbol:'!', label:'label_not_equals'};
const OP_TODAY = {symbol:'t', label:'label_today'};
const OP_THIS_WEEK = {symbol:'w', label:'label_this_week'};
const OP_AGO_LT = {symbol:'>t-', label:'label_less_than_ago'};
const OP_AGO_GT = {symbol:'<t-', label:'label_more_than_ago'};
const OP_AGO = {symbol:'t-', label:'label_ago'};
const OP_DATE_EQ = {symbol:'=d', label:'label_on'};
const OP_DATE_BETWEEN = {symbol:'<>d', label:'label_between'};
const OP_CONTAINS = {symbol:'~', label:'label_contains'};
const OP_NOT_CONTAINS = {symbol:'!~', label:'label_not_contains'};
const OP_EQ = {symbol:'=', label:'label_equals'};
const OP_NEQ = {symbol:'!', label:'label_not_equals'};
const OP_LEQ = {symbol:'<=', label:'label_less_or_equal'};
const OP_GEQ = {symbol:'>=', label:'label_greater_or_equal'};


angular.module('openproject.workPackages.config')

.constant('INITIALLY_SELECTED_COLUMNS', [
  { name: 'id' }, { name: 'project' }, { name: 'type' }, { name: 'status' },
  { name: 'priority' }, { name: 'subject' }, { name: 'assigned_to_id' }, { name: 'updated_at' }
])

.constant('OPERATORS_AND_LABELS_BY_FILTER_TYPE', {
  list: [
    OP_SEL_EQ,
    OP_SEL_NEQ
  ],
  list_model: [
    OP_SEL_EQ,
    OP_SEL_NEQ
  ],
  list_status: [
    {symbol:'o', label:'label_open_work_packages'},
    OP_SEL_EQ,
    OP_SEL_NEQ,
    {symbol:'c', label:'label_closed_work_packages'},
    OP_ALL
  ],
  list_optional: [
    OP_SEL_EQ,
    OP_SEL_NEQ,
    OP_NONE,
    OP_ALL
  ],
  list_subprojects: [
    OP_SEL_EQ,
    OP_NONE,
    OP_ALL
  ],
  date: [
    {symbol:'<t+', label:'label_in_less_than'},
    {symbol:'>t+', label:'label_in_more_than'},
    {symbol:'t+', label:'label_in'},
    OP_TODAY,
    OP_THIS_WEEK,
    OP_AGO_LT,
    OP_AGO_GT,
    OP_AGO,
    OP_DATE_EQ,
    OP_DATE_BETWEEN
  ],
  datetime_past: [
    OP_AGO_LT,
    OP_AGO_GT,
    OP_AGO,
    OP_TODAY,
    OP_THIS_WEEK
  ],
  string: [
    OP_EQ,
    OP_CONTAINS,
    OP_NEQ,
    OP_NOT_CONTAINS
  ],
  text: [
    OP_CONTAINS,
    OP_NOT_CONTAINS
  ],
  integer: [
    OP_EQ,
    OP_GEQ,
    OP_LEQ,
    OP_NONE,
    OP_ALL
  ]
})

.constant('AVAILABLE_WORK_PACKAGE_FILTERS', {
  status: { type: 'list_status', modelName: 'status' , order: 1, locale_name: 'status' },
  type: { type: 'list_model', modelName: 'type', order: 2, locale_name: 'type' },
  priority: { type: 'list_model', modelName: 'priority', order: 3, locale_name: 'priority' },
  assignee: { type: 'list_optional', modelName: 'user' , order: 4, locale_name: 'assigned_to' },
  author: { type: 'list_model', modelName: 'user' , order: 5, locale_name: 'author' },
  watcher: {type: 'list_model', modelName: 'user', order: 6, locale_name: 'watcher' },
  responsible: {type: 'list_optional', modelName: 'user', order: 6, locale_name: 'responsible' },
  version: {type: 'list_optional', modelName: 'version', order: 7, locale_name: 'fixed_version' },
  category: { type: 'list_optional', modelName: 'category', order: 7, locale_name: 'category' },
  memberOfGroup: {type: 'list_optional', modelName: 'group', order: 8, locale_name: 'member_of_group' },
  assignedToRole: {type: 'list_optional', modelName: 'role', order: 9, locale_name: 'assigned_to_role' },
  subject: { type: 'text', order: 10, locale_name: 'subject' },
  createdAt: { type: 'datetime_past', order: 11, locale_name: 'created_at' },
  updatedAt: { type: 'datetime_past', order: 12, locale_name: 'updated_at' },
  startDate: { type: 'date', order: 13, locale_name: 'start_date' },
  dueDate: { type: 'date', order: 14, locale_name: 'due_date' },
  estimatedTime: { type: 'integer', order: 15, locale_name: 'estimated_hours' },
  percentageDone: { type: 'integer', order: 16, locale_name: 'done_ratio' },
  project: { type: 'list_model', modelName: 'project', order: 17, locale_name: 'project' },
  subprojectId: { type: 'list_subprojects', modelName: 'sub_project', order: 18, locale_name: 'subproject' }
})

.constant('DEFAULT_SORT_CRITERIA', 'parent:desc')

.constant('MAX_SORT_ELEMENTS', 3)

.constant('DEFAULT_PAGINATION_OPTIONS', {
  page: 1,
  perPage: 10,
  perPageOptions: [10, 100, 500, 1000],
  maxVisiblePageOptions: 6,
  optionsTruncationSize: 1
});
