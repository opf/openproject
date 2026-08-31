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
    include ImportRuns::SelectProjectsDialog

    layout "admin"

    # The step a wizard action may submit depends on the state it is rendered in.
    # Mirrors the links in the ImportRuns::WizardStep* components; states absent
    # here render no action at all.
    STEPS_BY_STATE = {
      initial: %i[fetch_instance_meta],
      instance_meta_error: %i[fetch_instance_meta],
      instance_meta_done: %i[configure],
      configuring: %i[fetch_projects_meta],
      projects_meta_error: %i[fetch_projects_meta],
      projects_meta_done: %i[import],
      importing: %i[abort_import],
      import_error: %i[import revert],
      imported: %i[finalize revert],
      revert_error: %i[revert],
      finalizing_error: %i[finalize]
    }.freeze

    VALID_STEPS = STEPS_BY_STATE.values.flatten.uniq.freeze

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
      step = params[:step]
      change_step(step)
      stream_wizard do
        open_select_projects_dialog if step.present? && step.to_sym == :configure && @jira_import.in_state?(:configuring)
      end
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
      raise StandardError.new(I18n.t(:"admin.jira.run.remove_error")) if @jira_import.running?

      @jira_import.destroy!
      redirect_to admin_import_jira_path(@jira), status: :see_other
    end

    def history
      @history = @jira_import.history
    end

    private

    def change_step(step)
      return if step.blank?

      method_name = VALID_STEPS.detect { |i| i.to_s == step }
      raise ArgumentError, "Invalid step: #{step}" unless method_name
      raise ArgumentError, I18n.t(:"admin.jira.run.step_not_available") unless allowed_steps.include?(method_name)

      send(method_name)
    end

    def allowed_steps
      STEPS_BY_STATE.fetch(@jira_import.current_state.to_sym, [])
    end

    def handle_error(error)
      respond_to do |format|
        format.turbo_stream { render_error_turbo_stream(error) }
        format.html { redirect_after_error(error) }
      end
    end

    def render_error_turbo_stream(error)
      render_error_flash_message_via_turbo_stream(message: error.message.to_s)
      respond_with_turbo_streams
    end

    def redirect_after_error(error)
      flash[:error] = error.message
      redirect_to(admin_import_jira_run_path(jira_id: @jira.id, id: @jira_import.id))
    end

    def fetch_instance_meta
      @jira_import.transition_to!(:instance_meta_fetching)
    end

    def fetch_projects_meta
      @jira_import.transition_to!(:projects_meta_fetching)
    end

    def import
      raise StandardError, semantic_identifiers_required_message unless Setting::WorkPackageIdentifier.semantic?

      @jira_import.transition_to!(:importing)
    end

    def semantic_identifiers_required_message
      helpers.safe_join(
        [
          I18n.t(:"admin.jira.errors.semantic_identifiers_must_be_enabled.title"),
          link_translate(
            "admin.jira.errors.semantic_identifiers_must_be_enabled.description",
            links: { link: admin_settings_work_packages_identifier_path },
            external: true
          )
        ],
        " "
      )
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

    def find_jira_and_jira_import
      @jira = Import::Jira.find(params[:jira_id])
      @jira_import = Import::JiraImport.find(params[:id])
    end
  end
end
