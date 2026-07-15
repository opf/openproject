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

module Admin::Import::Jira
  class ImportRunsController < ApplicationController
    include OpTurbo::ComponentStream
    include ImportRuns::ComponentStreams

    layout "admin"

    VALID_STEPS = %i[
      fetch_instance_meta
      fetch_projects_meta
      configure
      import
      revert
      finalize
      abort_import
      resume
      retry
    ].freeze

    menu_item :jira_import

    before_action :require_admin
    before_action :find_jira_and_jira_import, only: %i[show continue remove revert_modal import_modal finalize_modal history]

    def show; end

    def create
      jira = Import::Jira.find(params[:jira_id])
      jira_import = Import::JiraImport.create!(author_id: current_user.id, jira_id: jira.id)
      redirect_to(admin_import_jira_run_path(jira_id: jira.id, id: jira_import.id))
    end

    def continue
      change_step(params[:step])
      stream_wizard
    rescue StandardError => e
      handle_error(e)
    end

    def import_modal
      respond_with_dialog Admin::Import::Jira::ImportRuns::ImportConfirmDialogComponent.new(jira_import: @jira_import)
    end

    def revert_modal
      respond_with_dialog Admin::Import::Jira::ImportRuns::RevertConfirmDialogComponent.new(jira_import: @jira_import)
    end

    def finalize_modal
      respond_with_dialog Admin::Import::Jira::ImportRuns::FinalizeConfirmDialogComponent.new(jira_import: @jira_import)
    end

    def remove
      raise StandardError.new(I18n.t(:"admin.jira.run.remove_error")) if @jira_import.status_running?

      @jira_import.destroy!
      redirect_to admin_import_jira_path(@jira), status: :see_other
    end

    def history
      @history = @jira_import.history
    end

    private

    def change_step(step)
      return if step.blank?

      method_name = VALID_STEPS.detect { |i| i == step.to_sym }
      raise ArgumentError, "Invalid step: #{step}" unless method_name

      send(method_name)
    end

    def handle_error(error)
      respond_to do |format|
        OpenProject.logger.error(error.backtrace)
        format.turbo_stream do
          render_error_flash_message_via_turbo_stream(message: error.message.to_s)
          respond_with_turbo_streams
        end
        format.html do
          flash[:error] = error.message
          redirect_to(admin_import_jira_run_path(jira_id: @jira.id, id: @jira_import.id))
        end
      end
    end

    def fetch_instance_meta
      @jira_import.transition_to!(:instance_meta_fetching)
    end

    def fetch_projects_meta
      @jira_import.transition_to!(:projects_meta_fetching)
    end

    def import
      @jira_import.transition_to!(:importing)
    end

    def configure
      @jira_import.transition_to!(:configuring)
    end

    def revert
      @jira_import.transition_to!(:reverting)
    end

    def finalize
      @jira_import.transition_to!(:finalizing)
    end

    def abort_import
      @jira_import.transition_to!(:import_aborting)
    end

    def retry
      last_transition = @jira_import.state_machine.last_transition
      if @jira_import.state_machine.status_error?
        @jira_import.transition_to!(last_transition.from_state)
      end
    end

    def resume
      last_transition = @jira_import.state_machine.last_transition
      if @jira_import.in_state?(:aborted)
        @jira_import.transition_to!(last_transition.from_state)
      end
    end

    def find_jira_and_jira_import
      @jira = Import::Jira.find(params[:jira_id])
      @jira_import = Import::JiraImport.find(params[:id])
    end
  end
end
