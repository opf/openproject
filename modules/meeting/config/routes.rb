# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

Rails.application.routes.draw do
  # Global route to show recurring meetings over all projects and create form from the global view
  resources :recurring_meetings, only: %i[index show new create] do
    collection do
      get :humanize_schedule, controller: "recurring_meetings/schedule", action: :humanize_schedule
    end
  end

  namespace :meetings do
    resource :filters, only: %i[show]
  end

  # Global route to show meetings over all projects and create form from the global view
  resources :meetings, only: %i[index show new create] do
    collection do
      get :new_dialog
      get "menu" => "meetings/menus#show"
      get :fetch_timezone
      get :fetch_templates
      get :project_items

      get "ical/:token", controller: "meetings/ical", action: :index, as: "ical_feed"

      get "templates", action: :index, controller: "meeting_templates", as: "templates"
      get "templates/new_dialog", action: :new_dialog, controller: "meeting_templates", as: "new_dialog_template"
      post "templates", action: :create, controller: "meeting_templates", as: "create_template"
    end
  end

  # All other routes are project scoped for correct permission handling
  resources :projects, only: %i[] do
    resources :meetings do
      collection do
        get :new_dialog
        get "menu" => "meetings/menus#show"
        get :fetch_timezone
        get :fetch_templates

        get "templates", action: :index, controller: "meeting_templates", as: "templates"
        get "templates/new_dialog", action: :new_dialog, controller: "meeting_templates", as: "new_dialog_template"
        post "templates", action: :create, controller: "meeting_templates", as: "create_template"
      end

      member do
        get :copy
        get :check_for_updates
        get :cancel_edit
        get :download_ics
        put :update_title
        get :details_dialog
        put :update_details
        put :change_state
        put :change_sharing
        post :notify
        get :history
        get :delete_dialog
        get :generate_pdf_dialog
        get :toggle_notifications_dialog
        post :toggle_notifications
        get :exit_draft_mode_dialog
        post :exit_draft_mode
      end

      resources :agenda_items, controller: "meeting_agenda_items" do
        collection do
          get :cancel_new
        end

        member do
          get :cancel_edit
          put :drop
          put :move
          get :move_to_next_dialog, action: :move_to_next_meeting_dialog
          post :move_to_next, action: :move_to_next_meeting
          get :duplicate_in_next_dialog, action: :duplicate_in_next_meeting_dialog
          post :duplicate_in_next, action: :duplicate_in_next_meeting
          put :move_to_section_dialog
          post :move_to_section
          get :convert_to_work_package_dialog
          post :convert_to_work_package
          post :refresh_convert_to_work_package_dialog
        end

        resources :outcomes, controller: "meeting_outcomes", except: %i[index show] do
          collection do
            get :cancel_new
            get :create_work_package_dialog
            post :create_work_package
            post :refresh_work_package_dialog
          end

          member do
            get :cancel_edit
          end
        end
      end

      resources :sections, controller: "meeting_sections" do
        collection do
          post :clear_backlog
          get :clear_backlog_dialog
        end

        member do
          post :cancel_edit
          put :drop
          put :move
        end
      end

      resources :participants, controller: "meeting_participants" do
        collection do
          get :manage_participants_dialog
          post :mark_all_attended
        end

        member do
          post :toggle_attendance
        end
      end

      resource :presentation, only: %i[show edit], controller: "meeting_presentation" do
        collection do
          get :check_for_updates
          post :start
        end
      end
    end

    resources :recurring_meetings do
      member do
        get :details_dialog
        get :download_ics
        get :delete_dialog
        get :delete_scheduled_dialog
        post :init
        delete :destroy_scheduled
        post :template_completed
        post :notify
        post :end_series
        get :end_series_dialog
      end
    end

    resources :work_packages, only: %i[] do
      resources :meetings, only: %i[] do
        collection do
          resources :tab, only: %i[index], controller: "work_package_meetings_tab", as: "meetings_tab" do
            get :count, on: :collection
          end
        end
      end

      resources :meeting_agenda_items, only: %i[] do
        collection do
          get :dialog, controller: "work_package_meetings_tab", action: :add_work_package_to_meeting_dialog
          post :create, controller: "work_package_meetings_tab", action: :add_work_package_to_meeting
          get :refresh_form, controller: "work_package_meetings_tab", action: :refresh_form
        end
      end
    end
  end
end
