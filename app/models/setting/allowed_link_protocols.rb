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

class Setting
  module AllowedLinkProtocols
    ALWAYS_ALLOWED = %w[http https mailto].freeze
    # A browser can execute these schemes from a link href.
    NEVER_ALLOWED = %w[data javascript vbscript].freeze

    def self.all
      (parse(Setting.allowed_link_protocols) + ALWAYS_ALLOWED).uniq
    end

    def self.custom
      all - ALWAYS_ALLOWED
    end

    def self.parse(value)
      entries = value.is_a?(Array) ? value : value.to_s.split(/\r?\n/)

      entries.filter_map { |protocol| sanitize_token(protocol) }
             .uniq
             .reject { |protocol| NEVER_ALLOWED.include?(protocol) }
    end

    def self.sanitize_token(protocol)
      protocol.to_s.strip.downcase.gsub(/[^a-z0-9+\-.]+/, "").presence
    end
    private_class_method :sanitize_token
  end
end
