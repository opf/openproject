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

module PushSubscriptions
  class SubscribeService
    def initialize(user:, session_id:, device:)
      @user = user
      @session_id = session_id
      @device = device
    end

    def call(endpoint:, resume: false)
      attempts = 0

      begin
        attempts += 1
        subscription = lookup(endpoint, resume)

        if subscription.nil?
          ServiceResult.success
        elsif held_by_another_user?(subscription)
          refused(subscription)
        else
          replace_session_subscription(subscription)
        end
      rescue ActiveRecord::RecordNotUnique
        retry if attempts < 2
        raise
      end
    end

    private

    attr_reader :user, :session_id, :device

    def lookup(endpoint, resume)
      if resume
        PushSubscription.find_by(user:, endpoint:)
      else
        PushSubscription.find_or_initialize_by(endpoint:)
      end
    end

    def held_by_another_user?(subscription)
      subscription.persisted? && subscription.user_id != user.id && subscription.session_id.present?
    end

    def replace_session_subscription(subscription)
      result = nil

      PushSubscription.transaction do
        target = take_over_dormant(subscription)
        result = target ? bind(target) : refused(subscription)
        raise ActiveRecord::Rollback if result.failure?
      end

      result
    end

    def take_over_dormant(subscription)
      return subscription if subscription.new_record? || subscription.user_id == user.id

      return unless PushSubscription.dormant.where(id: subscription.id).delete_all == 1

      PushSubscription.new(endpoint: subscription.endpoint)
    end

    def bind(subscription)
      PushSubscription.for_session(session_id).except_endpoint(subscription.endpoint).delete_all
      CreateService
        .new(user:, model: subscription)
        .call(user:, session_id:, suspended_at: nil, **device)
    end

    def refused(subscription)
      ServiceResult.failure(result: subscription).tap do |result|
        result.errors.add(:endpoint, :taken)
      end
    end
  end
end
