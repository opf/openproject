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

module API
  module V3
    module LlmCompletions
      class LlmCompletionsAPI < ::API::OpenProjectAPI
        namespace :ai do
          resources :completions do
            before do
              guard_feature_flag(:llm_completions_api)
              authorize_globally(:use_llm_completions)
            end

            helpers do
              def raise_llm_error(error)
                case error
                when ::Llm::Errors::NotReady
                  raise ::API::Errors::UnprocessableContent.new(I18n.t("llm.completions.errors.not_ready"),
                                                                details: { reason: error.status })
                when ::Llm::Errors::ConfigurationError
                  raise ::API::Errors::UnprocessableContent.new(I18n.t("llm.completions.errors.not_ready"),
                                                                details: { reason: :configuration })
                when ::Llm::Errors::ContextLengthError
                  raise ::API::Errors::UnprocessableContent.new(I18n.t("llm.completions.errors.context_too_long"))
                when ::Llm::Errors::RateLimitedError
                  raise ::API::Errors::TooManyRequests.new(message: I18n.t("llm.completions.errors.upstream_rate_limited"))
                else
                  raise UpstreamError
                end
              end
            end

            get do
              resolution = ::Llm::Runtime.for(::Llm::Completions::Complete::FEATURE)

              { _type: "LlmCompletionsAvailability", available: resolution.ready?,
                status: resolution.status, model: (resolution.model_id if resolution.ready?) }
            end

            post do
              request = ::Llm::Completions::Request.from_params(params)
              raise ::API::Errors::ErrorBase.create_and_merge_errors(request.errors) unless request.valid?

              unless ::Llm::Completions::RateLimit.new(current_user).allow?
                raise ::API::Errors::TooManyRequests.new(message: I18n.t("llm.completions.errors.rate_limited"))
              end

              completion = ::Llm::Completions::Complete.new(user: current_user, request:).call

              status 200
              {
                _type: "LlmCompletion",
                content: completion.content,
                toolCalls: completion.tool_calls,
                thinking: completion.thinking,
                model: completion.model_id,
                usage: { inputTokens: completion.input_tokens, outputTokens: completion.output_tokens }
              }
            rescue ::Llm::Errors::Error => e
              raise_llm_error(e)
            end
          end
        end
      end
    end
  end
end
