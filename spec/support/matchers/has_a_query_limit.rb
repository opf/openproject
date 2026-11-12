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

RSpec::Matchers.define :have_a_query_limit do |expected|
  supports_block_expectations

  match do |block|
    query_count(&block) <= expected
  end

  failure_message do |_actual|
    "Expected a maximum of #{expected} queries, got #{@recorder.count}:\n\n#{@recorder.message}"
  end

  def query_count(&)
    @recorder = ActiveRecord::QueryRecorder.new(&)
    @recorder.count
  end
end

module ActiveRecord
  class QueryRecorder
    attr_reader :log

    def initialize(&)
      @log = []
      ActiveSupport::Notifications.subscribed(method(:callback), "sql.active_record", &)
    end

    def callback(_name, _start, _finish, _message_id, values)
      return if %w(CACHE SCHEMA).include?(values[:name])

      @log << values[:sql]
    end

    delegate :count, to: :@log

    def message
      @log.join("\n\n")
    end
  end
end
