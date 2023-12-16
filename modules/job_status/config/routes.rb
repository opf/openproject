Rails.application.routes.draw do
  get '/job_statuses/:job_uuid',
      to: 'angular#empty_layout',
      as: 'job_status'
end
