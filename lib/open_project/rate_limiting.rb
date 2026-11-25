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

module OpenProject
  module RateLimiting
    module_function

    def active_rules
      @active_rules ||= []
    end

    def default_rules
      @default_rules ||= [
        LostPassword,
        APIV3,
        Login,
        Registration
      ]
    end

    def set_defaults!
      Rack::Attack.clear_configuration
      Rack::Attack.throttled_responder = ->(request) { OpenProject::RateLimiting.throttled_response(request) }
      Rack::Attack.blocklisted_responder = ->(request) { OpenProject::RateLimiting.blocklisted_response(request) }

      @active_rules = []
      default_rules.each do |rule|
        apply(rule)
      end
    end

    def apply(rule)
      unless rule < OpenProject::RateLimiting::Base
        raise ArgumentError.new("Rules need to subclass OpenProject::RateLimiting::Base")
      end

      active_rules << rule.new.apply! if rule.enabled?
    end

    def throttled_response(request)
      matched = request.env["rack.attack.matched"]
      rule = find_rule(matched)
      rule ? rule.response(request) : Base.new.response(request)
    end

    def blocklisted_response(request)
      matched = request.env["rack.attack.matched"]
      rule = find_rule(matched)
      rule ? rule.blocked_response : [403, {}, ["Forbidden\n"]]
    end

    def find_rule(matched)
      active_rules.find { |r| matched == r.rule_name || matched.start_with?("#{r.rule_name}/") }
    end
  end
end
