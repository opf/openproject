OpenProject::Application.routes.draw do
  resources :job_statuses,
            param: :job_uuid,
            controller: 'job_status/job_statuses',
            only: %i[show]
end
