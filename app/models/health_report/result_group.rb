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
  class ResultGroup
    class << self
      # Used for serialization in health report
      # Note: Because we deserialize from jsonb, we don't expect a string
      # but already parsed json
      def load(parsed_json)
        Array(parsed_json).map { |h| new(key: h.fetch("key"), results: h.fetch("results").map { |r| Result.load(r) }) }
      end

      # Used for serialization in health report
      # Note: Because we serialize into jsonb, we don't return a string (JSON.dump)
      # but return a hash/array directly.
      def dump(value)
        if value.is_a?(Array)
          value.map(&:to_h)
        else
          value.to_h
        end
      end
    end

    attr_reader :key, :results

    def initialize(key:, results: [])
      @key = key
      @results = results
    end

    def success? = results.all?(&:success?)

    def non_failure? = results.none?(&:failure?)

    def failure? = results.any?(&:failure?)

    def warning? = results.any?(&:warning?)

    def result_for(key)
      results.find { |r| r.key == key }
    end

    alias [] result_for

    def tally
      results.map(&:state).tally
    end

    def to_h
      { key:, results: results.map(&:to_h) }
    end
  end
end
