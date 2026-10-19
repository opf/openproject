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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module AI
  class TextTransformPanesController < ApplicationController
    include OpTurbo::ComponentStream
    include AI::TextTransformActionsFeature

    APPLY_EVENT = "op-dispatched:ai-text-transform:apply"
    CLOSED_EVENT = "op-dispatched:ai-text-transform:closed"

    before_action :require_login
    before_action :require_ai_text_transform_actions_feature
    authorization_checked! :create, :show, :destroy, :apply, :cancel
    before_action :validate_pane_params, except: :cancel
    before_action :find_run, only: %i[show apply cancel]
    before_action :resolve_context, only: :create

    def show
      return head(:no_content) unless run.terminal? || new_events?

      run.cancelled? ? close_pane : update_sections
      respond_with_turbo_streams unless performed?
    end

    def create
      append_pane(start_run)

      respond_with_turbo_streams
    end

    def destroy
      open_run = own_runs.find_by(uuid: params[:uuid])
      request_cancel(open_run) if open_run
      close_pane

      respond_with_turbo_streams
    end

    def apply
      return head(:unprocessable_entity) unless run.succeeded?

      dispatch_event_via_turbo_stream(APPLY_EVENT, detail: { requestId: pane_params[:request_id],
                                                             scope: pane_params[:scope],
                                                             text: pane_for(run).text })

      respond_with_turbo_streams
    end

    def cancel
      request_cancel(run)

      head :no_content
    end

    private

    attr_reader :pane_params, :context, :run

    def own_runs
      AI::TextTransformRun.where(user: current_user)
    end

    def find_run
      @run = own_runs.find_by!(uuid: params.expect(:uuid))
    end

    def new_events?
      run.events_after(pane_params[:after]).exists?
    end

    def request_cancel(cancellable)
      cancellable.update!(cancel_requested: true) unless cancellable.terminal?
    end

    def validate_pane_params
      @pane_params = AI::TextTransforms::PaneParamsContract.new.call(params.permit(*AI::TextTransforms::PaneParamsContract.keys).to_h)
      head :bad_request if pane_params.failure?
    end

    def context_ids
      pane_params.to_h.slice(*AI::TextTransforms::PaneParamsContract::CONTEXT_KEYS).compact
    end

    def resolve_context
      call = AI::TextTransforms::ResolveContext.new(user: current_user).call(**context_ids)
      return @context = call.result if call.success?

      call.errors.any? { |error| error.type == :error_not_found } ? render_404 : render_403
    end

    def start_run
      action, content = run_source
      call = AI::TextTransforms::CreateRun.new(user: current_user, action:, context:, content:).call
      call.success? ? pane_for(call.result) : rejected_pane(call.errors, action)
    end

    def run_source
      retry_of = pane_params[:retry_of]
      return [AI::TextTransformAction.find_by(id: pane_params[:action_id]), pane_params[:input].to_s] unless retry_of

      retried = own_runs.failed.find_by!(uuid: retry_of)
      [retried.action, retried.input]
    end

    def pane_for(pane_run)
      AI::TextTransforms::ResultPaneState.new(run: pane_run, scope: pane_params[:scope], request_id: pane_params[:request_id],
                                              work_package: context&.work_package, context_ids:)
    end

    def rejected_pane(errors, action)
      AI::TextTransforms::ResultPaneState.rejected(message: errors.full_messages.first,
                                                   label: action&.label.to_s,
                                                   scope: pane_params[:scope],
                                                   request_id: pane_params[:request_id],
                                                   context_ids:)
    end

    def append_pane(pane)
      turbo_streams << lambda {
        OpTurbo::StreamComponent
          .new(action: :append, target: nil, targets: "body",
               template: AI::TextTransforms::ResultPaneComponent.new(pane:).render_in(view_context))
          .render_in(view_context)
      }
    end

    def update_sections
      resolve_context
      return if performed?

      pane = pane_for(run)
      [AI::TextTransforms::ResultPaneComponent::Body, AI::TextTransforms::ResultPaneComponent::Footer].each do |section|
        update_via_turbo_stream(component: section.new(pane:))
      end
    end

    def close_pane
      remove_via_turbo_stream(component: AI::TextTransforms::ResultPaneComponent.new(pane: nil))
      dispatch_event_via_turbo_stream(CLOSED_EVENT, detail: { requestId: pane_params[:request_id] })
    end
  end
end
