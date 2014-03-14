angular.module('openproject.workPackages.config')

.constant('AVAILABLE_COLUMNS', [
  {
    custom_field: false,
    groupable: 'project',
    meta_data: { data_type: 'object', link: { display: true, model_type: 'project' } },
    name: 'project',
    sortable: 'projects.name',
    title: 'Project'
  },
  {
    custom_field: false,
    groupable: 'type',
    meta_data: { data_type: 'object', link: { display: true } },
    name: 'type',
    sortable: 'types.postition',
    title: 'Type'
  }
])

.constant('INITIALLY_SELECT_COLUMNS', [
  {
    custom_field: false,
    groupable: 'type',
    meta_data: { data_type: 'object', link: { display: true } },
    name: 'type',
    sortable: 'types.postition',
    title: 'Type'
  }
])

.constant('AVAILABLE_WORK_PACKAGE_FILTERS', {
  assigned_to_id: { name: 'Assignee', type: 'list_optional' }, // Note: we might want to put default "me" value here
  created_at: { name: 'Created on', type: 'date_past' },
  subject: { name: 'Subject', type: 'text' },
  estimated_hours: { name: 'Estimated time', type: 'integer' }
})