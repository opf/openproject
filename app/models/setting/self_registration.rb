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
  ##
  # Shorthand to common setting aliases to avoid checking values
  module SelfRegistration
    VALUES = {
      disabled: 0,
      activation_by_email: 1,
      manual_activation: 2,
      automatic_activation: 3
    }.freeze
    KEYS = VALUES.invert.merge(VALUES.invert.transform_keys(&:to_s)).freeze

    def self.values
      VALUES
    end

    def self.value(key:)
      VALUES[key]
    end

    def self.key(value:)
      KEYS[value]
    end

    def self.disabled
      value key: :disabled
    end

    def self.selected?(val)
      key(value: Setting.self_registration) == val.to_sym
    end

    def self.disabled?
      selected?(:disabled)
    end

    def self.enabled?
      !disabled?
    end

    def self.by_email
      value key: :activation_by_email
    end

    def self.by_email?
      selected?(:activation_by_email)
    end

    def self.manual
      value key: :manual_activation
    end

    def self.manual?
      selected?(:manual_activation)
    end

    def self.automatic
      value key: :automatic_activation
    end

    def self.automatic?
      selected?(:automatic_activation)
    end

    def self.unsupervised_registration?
      by_email? || automatic?
    end
  end
end
