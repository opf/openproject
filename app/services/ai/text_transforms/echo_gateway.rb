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

module AI
  module TextTransforms
    # Development stand-in that needs no LLM connection: reports ready and
    # streams the submitted content back word by word.
    class EchoGateway < Gateway
      ENV_KEY = "OPENPROJECT_AI_TEXT_TRANSFORM_ECHO_GATEWAY"

      def self.enabled?
        !Rails.env.production? && ActiveModel::Type::Boolean.new.cast(ENV.fetch(ENV_KEY, false)) == true
      end

      def initialize(delay: 0.05)
        super()
        @delay = delay
      end

      def readiness
        Readiness.new(true, nil)
      end

      def stream(system:, user:, **)
        text = echo_text(system:, user:)

        text.scan(/\S+\s*|\s+/).each do |chunk|
          yield chunk
          sleep(@delay) if @delay.positive?
        end

        text
      end

      private

      def echo_text(system:, user:)
        <<~TEXT.chomp
          #{user}

          ---

          _Echo gateway: no LLM connected. The action's instructions were:_

          > #{system.to_s.lines.map(&:chomp).join("\n> ")}
        TEXT
      end
    end
  end
end
