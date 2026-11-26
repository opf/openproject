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

module Projects
  module Types
    module Switch
      # The steps of a variant switch, shared by every page that starts one. The page provides:
      # - switch_selection: the Selection being switched
      # - switch_url, switch_confirmation_url, switch_impact_url: where each step posts
      # - refresh_after_switch: repaints what the switch changed on the page
      # and may override switch_params and switch_listed_projects.
      module Flow
        extend ActiveSupport::Concern

        include OpTurbo::ComponentStream

        private

        def respond_with_switch_dialog(selected: nil)
          respond_with_dialog DialogComponent.new(selection: switch_selection, selected:, params: switch_params,
                                                  confirmation_url: switch_confirmation_url,
                                                  impact_url: switch_impact_url)
        end

        def respond_with_switch_impact
          impact = switch_selection.impact(switch_selection.target(params[:target_id]))
          update_via_turbo_stream(component: ImpactComponent.new(impact:))

          respond_to_with_turbo_streams
        end

        def respond_with_switch_confirmation
          target = switch_selection.target(params[:target_id])
          refusal = switch_selection.refusal(target)
          return repaint_switch_form(target, refusal) if refusal

          close_dialog_via_turbo_stream(DialogComponent::DIALOG_ID)
          respond_with_dialog ConfirmDialogComponent.new(target:, url: switch_url, params: switch_params,
                                                         listed_projects: switch_listed_projects(target))
        end

        def respond_with_switch # rubocop:disable Metrics/AbcSize
          target = switch_selection.target(params[:target_id])
          refusal = switch_selection.refusal(target)
          return refuse_switch(refusal) if refusal

          result = ::WorkPackageTypes::ProjectAssignments
                     .new(user: current_user, variant: target)
                     .switch(::Project.where(id: switch_selection.projects), target:)
          close_dialog_via_turbo_stream(ConfirmDialogComponent::DIALOG_ID)
          refresh_after_switch
          flash_switch_result(result, target)

          respond_to_with_turbo_streams(status: result)
        end

        def switch_params = {}

        def switch_listed_projects(_target) = []

        def switch_selection = raise(SubclassResponsibilityError)

        def switch_url = raise(SubclassResponsibilityError)

        def switch_confirmation_url = raise(SubclassResponsibilityError)

        def switch_impact_url = raise(SubclassResponsibilityError)

        def refresh_after_switch = raise(SubclassResponsibilityError)

        def repaint_switch_form(target, message)
          update_via_turbo_stream(
            component: FormComponent.new(
              selection: switch_selection, selected: target || switch_selection.targets.first,
              confirmation_url: switch_confirmation_url, impact_url: switch_impact_url, params: switch_params,
              validation_message: message
            )
          )
          respond_to_with_turbo_streams(status: :unprocessable_content)
        end

        def refuse_switch(message)
          render_error_flash_message_via_turbo_stream(message:)
          respond_to_with_turbo_streams(status: :unprocessable_content)
        end

        def flash_switch_result(result, target) # rubocop:disable Metrics/AbcSize
          if result.success?
            render_success_flash_message_via_turbo_stream(
              message: I18n.t("projects.settings.types.switch.success", type: target.composite_name,
                                                                        count: switch_selection.projects.size)
            )
          else
            refused = result.dependent_results.reject(&:success?)
            render_error_flash_message_via_turbo_stream(
              message: refused.map { "#{it.result.name}: #{it.errors.full_messages.to_sentence}" }.to_sentence
            )
          end
        end
      end
    end
  end
end
