#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class Setting
  ##
  # Shorthand to common setting aliases to avoid checking values
  module SelfRegistration
    VALUES = {
      disabled: 0,
      activation_by_email: 1,
      manual_activation: 2,
      automatic_activation: 3
    }.freeze

    def self.values
      VALUES
    end

    def self.value(key:)
      VALUES[key]
    end

    def self.key(value:)
      VALUES.find { |k, v| v == value || v.to_s == value.to_s }&.first
    end

    def self.disabled
      value key: :disabled
    end

    def self.disabled?
      key(value: Setting.self_registration) == :disabled
    end

    def self.by_email
      value key: :activation_by_email
    end

    def self.by_email?
      key(value: Setting.self_registration) == :activation_by_email
    end

    def self.manual
      value key: :manual_activation
    end

    def self.manual?
      key(value: Setting.self_registration) == :manual_activation
    end

    def self.automatic
      value key: :automatic_activation
    end

    def self.automatic?
      key(value: Setting.self_registration) == :automatic_activation
    end
  end
end
