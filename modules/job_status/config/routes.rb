Rails.application.routes.draw do
  get "/job_statuses/:job_uuid",
      to: "job_statuses#show",
      as: "job_status"
end
