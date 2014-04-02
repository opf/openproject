angular.module('openproject.workPackages.config')

.constant('INITIALLY_SELECTED_COLUMNS', ['id', 'project', 'type', 'status', 'priority', 'subject', 'assigned_to_id', 'updated_at'])

.constant('OPERATORS_AND_LABELS_BY_FILTER_TYPE', {
  list: {'=':'is','!':'is not'},
  list_model: {'=':'is','!':'is not'},
  list_status: {'o':'open','=':'is','!':'is not','c':'closed','*':'all'}, // TODO RS: Need a generalised solution
  list_optional: {'=':'is','!':'is not','!*':'none','*':'all'},
  list_subprojects: {'*':'all','!*':'none','=':'is'},
  date: {'<t+':'in less than','>t+':'in more than','t+':'in','t':'today','w':'this week','>t-':'less than days ago','<t-':'more than days ago','t-':'days ago'},
  date_past: {'>t-':'less than days ago','<t-':'more than days ago','t-':'days ago','t':'today','w':'this week'},
  string: {'=':'is','~':'contains','!':'is not','!~':"doesn't contain"},
  text: {'~':'contains','!~':"doesn't contain"},
  integer: {'=':'is','>=':'>=','<=':'<=','!*':'none','*':'all'}
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
})

.constant('DEFAULT_SORT_CRITERIA', 'parent:desc')

.constant('DEFAULT_PAGINATION_OPTIONS', {
  page: 1,
  perPage: 10,
  perPageOptions: [10, 20, 50, 100, 500, 1000]
});
