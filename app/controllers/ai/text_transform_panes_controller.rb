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

    ACCEPTED_EVENT = "op-dispatched:ai-text-transform:accepted"
    CLOSED_EVENT = "op-dispatched:ai-text-transform:closed"

    before_action :require_login
    before_action :require_ai_text_transform_actions_feature
    authorization_checked! :create, :show, :destroy, :apply, :cancel
    before_action :validate_pane_params, except: %i[destroy cancel]
    before_action :find_run, only: %i[show apply cancel]
    before_action :find_retried_run, only: :create
    before_action :resolve_context, only: %i[create apply]

    def show
      return head(:no_content) if unchanged?

      run.cancelled? ? close_pane : update_sections
      respond_with_turbo_streams unless performed?
    end

    def create
      append_to_body_via_turbo_stream(component: AI::TextTransforms::ResultPaneComponent.new(pane: start_run))

      respond_with_turbo_streams
    end

    def destroy
      own_runs.find_by(uuid: params[:uuid])&.request_cancel!
      close_pane

      respond_with_turbo_streams
    end

    def apply
      return head(:unprocessable_entity) unless run.succeeded?

      dispatch_event_via_turbo_stream(ACCEPTED_EVENT, detail: { requestId: request_id,
                                                                scope: pane_params[:scope],
                                                                text: pane_for(run).text })

      respond_with_turbo_streams
    end

    def cancel
      run.request_cancel!

      head :no_content
    end

    private

    attr_reader :run, :retried_run

    def own_runs
      AI::TextTransformRun.where(user: current_user)
    end

    def find_run
      @run = own_runs.find_by(uuid: params[:uuid])
      head :not_found unless run
    end

    def find_retried_run
      return unless pane_params[:retry_of]

      @retried_run = own_runs.failed.find_by(uuid: pane_params[:retry_of])
      head :not_found unless retried_run
    end

    def pane_params
      @pane_params ||= pane_contract.call(params.permit(*AI::TextTransforms::PaneParamsContract::KEYS).to_h)
    end

    def pane_contract
      AI::TextTransforms::PaneParamsContract.new
    end

    def validate_pane_params
      head :bad_request if pane_params.failure?
    end

    def request_id
      pane_params[:request_id] unless pane_params.error?(:request_id)
    end

    def unchanged?
      return false if run.events_after(pane_params[:after]).exists?

      seen_state = pane_params[:state]
      seen_state ? seen_state == pane_for(run).state : !run.terminal?
    end

    def context
      @context || AI::TextTransforms::Context.none
    end

    def resolve_context
      call = AI::TextTransforms::ResolveContext.new(user: current_user).call(**context_ids)
      return @context = call.result if call.success?

      head(call.errors.any? { |error| error.type == :error_not_found } ? :not_found : :forbidden)
    end

    def context_ids
      pane_params.to_h.slice(*AI::TextTransforms::PaneParamsContract::CONTEXT_KEYS).compact
    end

    def start_run
      action, content = run_source
      call = AI::TextTransforms::CreateRun.new(user: current_user, action:, context:, content:).call
      call.success? ? pane_for(call.result) : rejected_pane(call.errors, action)
    end

    def run_source
      return [retried_run.action, retried_run.input] if retried_run

      [AI::TextTransformAction.find_by(id: pane_params[:action_id]), pane_params[:input].to_s]
    end

    def pane_for(pane_run)
      AI::TextTransforms::ResultPaneState.new(run: pane_run, scope: pane_params[:scope], request_id:, context:)
    end

    def rejected_pane(errors, action)
      AI::TextTransforms::ResultPaneState.rejected(message: errors.full_messages.first,
                                                   label: action&.label.to_s,
                                                   scope: pane_params[:scope],
                                                   request_id:,
                                                   context:)
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
      dispatch_event_via_turbo_stream(CLOSED_EVENT, detail: { requestId: request_id }) if request_id
    end
  end
end
