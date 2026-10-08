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
    module Documents
      class CollaborationTokenAPI < ::API::OpenProjectAPI
        resources :collaboration_token do
          helpers do
            def collaboration_document
              @collaboration_document ||= document
            end

            def authorize_collaboration_token_request
              authorize_in_project(:view_documents, project: collaboration_document.project)
              ensure_collaboration_available
            end

            def ensure_collaboration_available
              if !collaboration_document.collaborative?
                raise ::API::Errors::UnprocessableContent.new(
                  I18n.t("documents.collaboration_token.errors.not_collaborative")
                )
              elsif !collaboration_document.real_time_collaboration_available?
                raise ::API::Errors::UnprocessableContent.new(
                  I18n.t("documents.collaboration_token.errors.collaboration_disabled")
                )
              end
            end

            def collaboration_token_response(token_result)
              header "Cache-Control", "no-store"
              status 201

              CollaborationTokenRepresenter.new(
                CollaborationTokenRepresenter::CollaborationToken.from_token_result(collaboration_document,
                                                                                    token_result),
                current_user:
              )
            end

            def fail_token_creation
              raise ::API::Errors::SafeInternalError.new(I18n.t("api_v3.errors.code_500"))
            end
          end

          after_validation do
            authorize_collaboration_token_request
          end

          params do
            optional :token, type: String, desc: "A previously issued collaboration token to revoke"
          end

          post do
            previous_token = declared_params[:token].presence
            result = ::Documents::OAuth::TokenWithMetadataService
              .new(user: current_user,
                   document: collaboration_document,
                   project: collaboration_document.project,
                   previous_token:)
              .call

            if result.success?
              collaboration_token_response(result.result)
            elsif previous_token && result.includes_error?(:token, :invalid)
              raise ::API::Errors::UnprocessableContent.new(result.message)
            else
              fail_token_creation
            end
          end
        end
      end
    end
  end
end
