# frozen_string_literal: true

Rails.application.routes.draw do
  # Per-user shortcut tips / badges (0019). Not project-scoped: the choice applies everywhere.
  patch "test_management/hotkey_preferences", to: "test_management/hotkey_preferences#update",
                                              as: :test_management_hotkey_preferences

  scope "projects/:project_id", as: "project" do
    namespace :test_management do
      # Bulk routes before resources :test_cases so /test_cases/bulk is not
      # captured as test_cases#update with id "bulk".
      namespace :test_cases do
        resource :bulk, only: [], controller: "bulk" do
          get :edit
          get :delete_dialog, defaults: { format: :turbo_stream }
          patch :update
          put :update
          post :move
          post :copy
          delete :destroy
        end
      end
      resources :test_cases, constraints: { id: /\d+/ } do
        member do
          get :delete_dialog, defaults: { format: :turbo_stream }
          post :restore
        end
      end
      resources :suites, only: %i[index create update destroy]
      resources :test_runs do
        member do
          get :complete_dialog, defaults: { format: :turbo_stream }
          get :cancel_dialog, defaults: { format: :turbo_stream }
          get :delete_dialog, defaults: { format: :turbo_stream }
          post :complete
          post :cancel
          post :reopen
        end
        resources :run_cases, only: %i[show update], controller: "test_run_cases" do
          resources :attachments, only: %i[create destroy], controller: "test_run_attachments"
        end
        resources :attachments, only: %i[create destroy], controller: "test_run_attachments"
        resources :iterations, only: %i[create], controller: "test_run_iterations"
      end
      resources :milestones do
        member do
          post :start
          post :complete
          post :reopen
        end
      end
      resources :test_plans do
        member do
          post :complete
          post :reopen
          post :rerun
        end
        resources :test_plan_entries, only: %i[create update destroy]
      end
      resource :project_settings, only: %i[show update], controller: "project_settings"
      resources :labels, only: %i[create update destroy], path: "project_settings/labels"
      resources :configuration_groups, only: %i[create update destroy], path: "project_settings/configuration_groups" do
        resources :configurations, only: %i[create update destroy]
      end
      resources :ci_connections, only: %i[create update destroy], path: "project_settings/ci_connections" do
        member { post :check }
      end
      resources :ci_triggers, only: %i[new create]
      get "exports/test_cases", to: "exports#test_cases", as: :export_test_cases
      get "exports/test_runs/:id", to: "exports#test_run", as: :export_test_run
      get "exports/milestones/:id", to: "exports#milestone", as: :export_milestone
      get "exports/test_plans/:id", to: "exports#test_plan", as: :export_test_plan
      get "menu", to: "menus#show"
      # The Executions placeholder was dropped (0013): test runs (with their iterations) are the
      # single execution entity. Old bookmarks go to the Runs list. A relative target keeps the
      # relative URL root (script_name).
      get "placeholders/executions",
          to: redirect("projects/%{project_id}/test_management/test_runs", status: 301),
          as: nil
      # Test Assistant 🪄 (0014): Generate and Chat on one page (?tab=generate|chat).
      get "assistant", to: "assistant#show", as: :assistant
      patch "assistant/provider", to: "assistant#select_provider", as: :assistant_provider
      post "assistant/generations", to: "assistant#generate", as: :assistant_generations
      get "assistant/generations/:id", to: "assistant#generation", as: :assistant_generation
      get "assistant/generations/:id/status", to: "assistant#generation_status", as: :assistant_generation_status
      post "assistant/generations/:id/cancel", to: "assistant#cancel_generation", as: :cancel_assistant_generation
      post "assistant/generations/:id/retry", to: "assistant#retry_generation", as: :retry_assistant_generation
      post "assistant/generations/:id/save", to: "assistant#save_drafts", as: :save_assistant_generation

      post "assistant/messages", to: "assistant#chat", as: :assistant_messages
      delete "assistant/messages", to: "assistant#clear"
      post "assistant/messages/:id/confirm", to: "assistant#confirm", as: :confirm_assistant_message
      post "assistant/messages/:id/cancel", to: "assistant#cancel", as: :cancel_assistant_message
      # The former Generate and Chat placeholders open the matching assistant tab.
      get "placeholders/generate",
          to: redirect("projects/%{project_id}/test_management/assistant?tab=generate", status: 301),
          as: nil
      get "placeholders/chat",
          to: redirect("projects/%{project_id}/test_management/assistant?tab=chat", status: 301),
          as: nil
      get "placeholders/:page", to: "placeholders#show", as: :placeholder
    end
  end

  # Work package "Testing" tab content (Turbo frame) and its counter.
  resources :work_packages, only: %i[] do
    get "test_management/tab", to: "test_management/work_package_testing_tab#index", as: :test_management_tab
    get "test_management/tab/count", to: "test_management/work_package_testing_tab#count", as: :test_management_tab_count
  end

  namespace :test_management do
    namespace :admin do
      resource :settings, only: %i[show update]
      # Saved AI providers of the Test Assistant (0021).
      resources :assistant_providers, except: %i[show] do
        post :make_default, on: :member
        collection do
          post :provider_form
          # The edit form carries _method=patch (Rack::MethodOverride), so the button's formaction
          # arrives as PATCH; the plain POST is accepted too.
          match :test_connection, via: %i[post patch]
        end
      end
    end
  end
end
