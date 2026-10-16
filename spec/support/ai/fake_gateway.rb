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

module AI
  module TextTransforms
    class FakeGateway < Gateway
      attr_reader :calls

      def initialize(ready: true, deltas: [], error: nil, raise_after: nil, before_each: -> {})
        super()
        @ready = ready
        @deltas = deltas
        @error = error
        @raise_after = raise_after
        @before_each = before_each
        @calls = []
      end

      def readiness
        Readiness.new(@ready, @ready ? nil : :fake)
      end

      def stream(system:, user:, timeout:)
        @calls << { system:, user:, timeout: }
        raise @error if @error && @raise_after.nil?

        @deltas.each_with_index do |delta, index|
          raise @error if @error && index == @raise_after

          @before_each.call
          yield delta
        end

        @deltas.join
      end
    end
  end
end
