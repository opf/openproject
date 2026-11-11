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

# Lets a failed streaming request keep the HTTP status the server answered with.
#
# RubyLLM derives the status of a failed stream from the error body alone: the
# OpenAI provider reads +error.type+ and reports anything other than
# +server_error+, +rate_limit_exceeded+ or +insufficient_quota+ as a 400. OpenAI
# itself answers a rate limit with +type: "requests"+, and self-hosted servers
# use types of their own, so a 429 arrives as a bad request and a 401 likewise.
#
# Only statuses that RubyLLM::ErrorMiddleware maps to an error class of their
# own are taken from the response. Any other, 413 and 422 among them, keeps the
# body's 400, because the middleware recognises a context length message only
# on 400 and 429. An error event inside a stream that started with 200 keeps
# the body's status too.
module OpenProject
  module Llm
    module Patches
      module RubyLLMStreamErrorStatus
        CLASSIFIED_STATUSES = [401, 402, 403, 429, 500, 502, 503, 504, 529].freeze

        private

        def build_stream_error_response(parsed_data, env, status)
          http_status = env&.status

          super(parsed_data, env, CLASSIFIED_STATUSES.include?(http_status) ? http_status : status)
        end
      end
    end
  end
end
