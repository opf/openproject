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

module Notifications
  # Validates notifications that are created on behalf of the current user
  # mentioning another user in a resource, e.g. a document
  # (see Notifications::CreateFromApiService).
  #
  # A resource type needs to opt in to this by defining `api_mention_permission`
  # on its Notifications::CreateFromModelService strategy. That permission is required
  # for the mentioning user while the strategy's `permission` is required for the
  # mentioned user (recipient).
  class CreateMentionFromApiContract < CreateContract
    validate :validate_resource_mentionable
    validate :validate_recipient_mentionable

    protected

    # Only mentions can be created this way. This replaces the check of the
    # parent contract which only requires a reason to be present.
    def validate_reason_present
      errors.add(:reason, :inclusion) unless model.reason_mentioned?
    end

    def validate_resource_mentionable
      if strategy.nil?
        errors.add(:resource, :mentions_not_supported)
      elsif !resource_visible?
        errors.add(:base, :error_not_found)
      elsif !user.allowed_in_project?(strategy.api_mention_permission, resource_project)
        errors.add(:base, :error_unauthorized)
      end
    end

    def validate_recipient_mentionable
      return if model.recipient.nil? || strategy.nil? || !resource_visible?

      if !recipient_active?
        errors.add(:recipient, :not_an_active_user)
      elsif !recipient_allowed?
        errors.add(:recipient, :not_allowed)
      end
    end

    private

    def strategy
      return @strategy if defined?(@strategy)

      strategy = Notifications::CreateFromModelService.strategy_for(model.resource_type)

      @strategy = strategy.respond_to?(:api_mention_permission) ? strategy : nil
    end

    def resource_visible?
      return @resource_visible if defined?(@resource_visible)

      @resource_visible = model.resource.present? && model.resource.visible?(user)
    end

    def recipient_active?
      model.recipient.active? && !model.recipient.builtin?
    end

    def recipient_allowed?
      model.recipient.allowed_in_project?(strategy.permission(nil, :mentioned), resource_project)
    end

    def resource_project
      model.resource.project
    end
  end
end
