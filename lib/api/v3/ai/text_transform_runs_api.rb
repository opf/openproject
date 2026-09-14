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

module API
  module V3
    module AI
      class TextTransformRunsAPI < ::API::OpenProjectAPI
        resources :ai_text_transform_runs do
          helpers do
            def context_from_params
              if params[:workPackageId]
                work_package_context
              elsif params[:projectId]
                new_work_package_context
              else
                ::AI::TextTransforms::Context.none
              end
            end

            def work_package_context
              work_package = WorkPackage.visible.find(params[:workPackageId])
              authorize_in_work_package(:edit_work_packages, work_package:)
              ::AI::TextTransforms::Context.for_work_package(work_package)
            end

            def new_work_package_context
              project = Project.visible(current_user).find(params[:projectId])
              authorize_in_project(:add_work_packages, project:)
              type = project.enabled_types.find(params[:typeId])
              ::AI::TextTransforms::Context.for_new_work_package(project:, type:)
            end

            def run_representer(run, after: 0)
              TextTransformRunRepresenter.new(run, current_user:, after:)
            end

            def raise_create_failure(errors)
              unavailable = errors.details[:base].find { |detail| detail[:error] == :not_available }
              raise ::API::Errors::ErrorBase.create_and_merge_errors(errors) unless unavailable

              raise ::API::Errors::UnprocessableContent.new(
                "#{I18n.t('api_v3.errors.ai_text_transform.action_not_available')} (#{unavailable[:reason]})"
              )
            end
          end

          params do
            requires :actionId, type: Integer
            requires :content, type: String
            optional :workPackageId, type: Integer
            optional :projectId, type: Integer
            optional :typeId, type: Integer
            mutually_exclusive :workPackageId, :projectId
            all_or_none_of :projectId, :typeId
          end
          post do
            raise ::API::Errors::Unauthorized unless current_user.logged?

            context = context_from_params
            action = ::AI::TextTransformAction.find_by(id: params[:actionId])
            call = ::AI::TextTransforms::CreateRun
                     .new(user: current_user, action:, context:, content: params[:content])
                     .call

            raise_create_failure(call.errors) if call.failure?

            status 202
            run_representer(call.result)
          end

          route_param :uuid, type: String do
            after_validation do
              @run = ::AI::TextTransformRun.find_by(uuid: params[:uuid], user_id: current_user.id)
              raise ::API::Errors::NotFound unless @run
            end

            params do
              optional :after, type: Integer, default: 0, values: ->(value) { value >= 0 }
            end
            get do
              run_representer(@run, after: params[:after])
            end

            namespace :cancel do
              post do
                @run.update!(cancel_requested: true) unless @run.terminal?
                status 204
              end
            end
          end
        end
      end
    end
  end
end
