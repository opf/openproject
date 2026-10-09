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

module AI
  # Demo only (AI-126): the result pane over Turbo. The editor plugin requests it directly, like the
  # wiki page link macro requests its dialog. It starts a run like the run API does (AI-136), appends
  # the pane to the body, streams the formatted text on every poll and hands the finished text back
  # to the editor through a dispatched event.
  class TextTransformPanesController < ApplicationController
    include OpTurbo::ComponentStream

    APPLY_EVENT = "op-dispatched:ai-text-transform:apply"
    CLOSED_EVENT = "op-dispatched:ai-text-transform:closed"
    CONTEXT_PARAMS = %i[work_package_id project_id type_id].freeze

    before_action :require_login
    no_authorization_required! :create, :show, :destroy, :apply, :cancel
    before_action :find_run, only: %i[show apply cancel]

    def show
      return head(:no_content) unless @run.terminal? || new_events?

      pane = pane_for(@run, work_package: poll_work_package)
      if pane.state == "cancelled"
        close_pane(pane.request_id)
      else
        update_sections(pane, %i[body footer])
      end

      respond_with_turbo_streams
    end

    def create
      context = resolve_context
      return render_403 unless context

      append_pane(start_run(context))

      respond_with_turbo_streams
    end

    def destroy
      run = own_runs.find_by(uuid: params[:uuid])
      run.update!(cancel_requested: true) if run && !run.terminal?
      close_pane(pane_for(run).request_id)

      respond_with_turbo_streams
    end

    def apply
      return head(:unprocessable_entity) unless @run.succeeded?

      pane = pane_for(@run)
      dispatch_event_via_turbo_stream(APPLY_EVENT, detail: { requestId: pane.request_id, scope: pane.scope, text: pane.text })

      respond_with_turbo_streams
    end

    # A pane that disappears while generating (replaced by a new one, page left) stops its run.
    def cancel
      @run.update!(cancel_requested: true) unless @run.terminal?

      head :no_content
    end

    private

    def own_runs
      AI::TextTransformRun.where(user: current_user)
    end

    def find_run
      @run = own_runs.find_by!(uuid: params.expect(:uuid))
    end

    def new_events?
      @run.events.maximum(:seq).to_i > params[:after].to_i
    end

    def resolve_context
      if params[:work_package_id].present?
        work_package_context
      elsif params[:project_id].present?
        new_work_package_context
      else
        AI::TextTransforms::Context.none
      end
    end

    def work_package_context
      work_package = WorkPackage.visible.find(params.expect(:work_package_id))
      return unless current_user.allowed_in_work_package?(:edit_work_packages, work_package)

      AI::TextTransforms::Context.for_work_package(work_package)
    end

    def new_work_package_context
      project = Project.visible.find(params.expect(:project_id))
      return unless current_user.allowed_in_project?(:add_work_packages, project)

      AI::TextTransforms::Context.for_new_work_package(project:, type: project.enabled_types.find(params.expect(:type_id)))
    end

    def start_run(context)
      action, content = run_source
      call = AI::TextTransforms::CreateRun.new(user: current_user, action:, context:, content:, demo_fault:).call
      call.success? ? pane_for(call.result, work_package: context.work_package) : rejected_pane(call.errors, action)
    end

    # Try again repeats a run of the user's with its action and input.
    def run_source
      return [AI::TextTransformAction.find_by(id: params[:action_id]), params[:input].to_s] if params[:retry_of].blank?

      retried = own_runs.find_by!(uuid: params.expect(:retry_of))
      [retried.action, retried.input]
    end

    def rejected_pane(errors, action)
      AI::TextTransforms::ResultPaneState.rejected(message: errors.full_messages.first,
                                                   label: action&.label.to_s,
                                                   scope: params[:scope],
                                                   request_id: params[:request_id],
                                                   context_ids:)
    end

    def demo_fault
      params.fetch(:demo_fault, nil).presence_in(AI::TextTransforms::DemoFaultGateway::FAULTS)
    end

    def pane_for(run, work_package: nil)
      AI::TextTransforms::ResultPaneState.new(run:, scope: params[:scope], request_id: params[:request_id],
                                              work_package:, context_ids:)
    end

    def context_ids
      params.permit(*CONTEXT_PARAMS).to_h.transform_values(&:to_i).select { |_, id| id.positive? }
    end

    def poll_work_package
      WorkPackage.visible.find_by(id: params[:work_package_id]) if params[:work_package_id].present?
    end

    # Like the dialog stream action, the pane goes straight into the body; Turbo's append replaces an
    # open pane with the same id.
    def append_pane(pane)
      turbo_streams << OpTurbo::StreamComponent
        .new(action: :append, target: nil, targets: "body",
             template: AI::TextTransforms::ResultPaneComponent.new(pane:).render_in(view_context))
        .render_in(view_context)
    end

    def update_sections(pane, sections)
      sections.each do |section|
        update_via_turbo_stream(component: AI::TextTransforms::ResultPaneSectionComponent.new(section:, pane:))
      end
    end

    def close_pane(request_id)
      remove_via_turbo_stream(component: AI::TextTransforms::ResultPaneComponent.new(pane: nil))
      dispatch_closed(request_id) if request_id
    end

    def dispatch_closed(request_id)
      dispatch_event_via_turbo_stream(CLOSED_EVENT, detail: { requestId: request_id })
    end
  end
end
