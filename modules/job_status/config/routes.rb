Rails.application.routes.draw do
  get "/job_statuses/dialog/:job_uuid", to: "job_statuses#dialog", as: "job_status_dialog"
  get "/job_statuses/dialog/:job_uuid/body", to: "job_statuses#dialog_body", as: "job_status_dialog_body"
  get "/job_statuses/:job_uuid",
      to: "job_statuses#show",
      as: "job_status"
end
