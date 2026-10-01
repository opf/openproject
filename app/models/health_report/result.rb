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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class HealthReport
  class Result
    class << self
      def skipped(key)
        new(key:, state: :skipped, code: nil, context: nil)
      end

      def success(key)
        new(key:, state: :success, code: nil, context: nil)
      end

      def failure(key, code, context)
        new(key:, state: :failure, code:, context:)
      end

      def warning(key, code, context)
        new(key:, state: :warning, code:, context:)
      end

      # Used for deserialization
      def load(parsed_json)
        new(
          key: parsed_json.fetch("key"),
          state: parsed_json.fetch("state"),
          code: parsed_json.fetch("code"),
          context: parsed_json.fetch("context")
        )
      end
    end

    attr_reader :key, :state, :code, :context

    def initialize(key:, state:, code:, context:)
      @key = key
      @state = state.to_sym
      @code = code
      @context = context
    end

    def success? = state == :success

    def failure? = state == :failure

    def warning? = state == :warning

    def skipped? = state == :skipped

    def to_h
      { key:, state:, code:, context: }
    end
  end
end
