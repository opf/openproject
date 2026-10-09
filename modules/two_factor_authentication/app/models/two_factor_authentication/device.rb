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

module TwoFactorAuthentication
  class Device < ApplicationRecord
    default_scope { order("id ASC") }

    belongs_to :user
    validates_presence_of :user_id
    validates_presence_of :identifier

    # Check uniqueness of default for this type
    validate :cannot_set_default_if_exists

    def self.get_default
      find_by(default: true, active: true)
    end

    def self.get_active
      where(active: true)
    end

    def self.has_default?(user)
      Device.exists?(user_id: user.id, active: true, default: true)
    end

    def has_default?
      self.class.has_default? user
    end

    def has_other_default?
      if persisted?
        Device.where.not(id:).exists?(active: true, default: true, user:)
      else
        has_default?
      end
    end

    ##
    # Make the device active, and set it as default if no other device exists
    def confirm_registration_and_save
      self.active = true
      self.default = !has_default?

      save
    end

    def identifier
      value = read_attribute(:identifier)

      value || default_identifier
    end

    def redacted_identifier
      identifier
    end

    def default_identifier
      if user.present?
        "#{name} (#{user.login})"
      else
        name
      end
    end

    def name
      model_name.human
    end

    def active?
      active == true
    end

    def make_default!
      return false unless active?

      Device.transaction do
        Device.where(user_id:).update_all(default: false)
        update_column(:default, true)
        true
      end
    end

    def channel=(value)
      super(value.to_sym)
    end

    def channel
      value = read_attribute(:channel)
      return if value.nil?

      value.to_sym
    end

    def self.device_type
      raise SubclassResponsibilityError
    end

    def self.available_channels_in_strategy
      strategy_class = manager.get_strategy(device_type)
      strategy_class.supported_channels & supported_channels
    end

    def input_based?
      true
    end

    private

    def self.manager
      ::OpenProject::TwoFactorAuthentication::TokenStrategyManager
    end

    def cannot_set_default_if_exists
      if default && has_other_default?
        errors.add :default, :default_already_exists
      end

      true
    end
  end
end
