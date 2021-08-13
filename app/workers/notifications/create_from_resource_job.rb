#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

# TODO: Test and check whether the difference to the CreateFromJournalJob can be extracted into the strategy
class Notifications::CreateFromResourceJob < ApplicationJob
  queue_with_priority :notification

  def perform(resource, send_notifications)
    self.resource = resource

    return if abort_sending?(send_notifications)
    return unless supported?

    notification_receivers.each do |recipient_id, channel_reasons|
      create_notification(recipient_id,
                          channel_reasons)
    end
  end

  private

  attr_accessor :resource

  def create_notification(recipient_id, channel_reasons)
    notification_attributes = {
      recipient_id: recipient_id,
      project: project,
      resource: resource,
      journal: nil,
      actor: user_with_fallback
    }.merge(channel_attributes(channel_reasons))

    Notifications::CreateService
      .new(user: user_with_fallback)
      .call(notification_attributes)
  end

  def channel_attributes(channel_reasons)
    channel_attributes_mail(channel_reasons)
      .merge(channel_attributes_mail_digest(channel_reasons))
      .merge(channel_attributes_ian(channel_reasons))
  end

  def channel_attributes_mail(channel_reasons)
    {
      read_mail: strategy.supports_mail? && channel_reasons.keys.include?('mail') ? false : nil,
      reason_mail: strategy.supports_mail? && channel_reasons['mail']&.first
    }
  end

  def channel_attributes_mail_digest(channel_reasons)
    {
      read_mail_digest: strategy.supports_mail_digest? && channel_reasons.keys.include?('mail_digest') ? false : nil,
      reason_mail_digest: strategy.supports_mail_digest? && channel_reasons['mail_digest']&.first
    }
  end

  def channel_attributes_ian(channel_reasons)
    {
      read_ian: strategy.supports_ian? && channel_reasons.keys.include?('in_app') ? false : nil,
      reason_ian: strategy.supports_ian? && channel_reasons['in_app']&.first
    }
  end

  def notification_receivers
    receivers = receivers_hash

    strategy.reasons.each do |reason|
      add_receivers_by_reason(receivers, reason)
    end

    remove_self_recipient(receivers)

    receivers
  end

  def add_receivers_by_reason(receivers, reason)
    add_receiver(receivers, send(:"settings_of_#{reason}"), reason)
  end

  def settings_of_subscribed
    applicable_settings(strategy.subscribed_users(resource),
                        project,
                        :all)
  end

  def settings_of_watched
    applicable_settings(strategy.watcher_users(resource),
                        project,
                        :watched)
  end

  def applicable_settings(user_scope, project, reason)
    NotificationSetting
      .applicable(project)
      .where(reason => true)
      .where(user: user_scope.where(id: User.allowed(strategy.permission, project)))
  end

  def send_notification?(send_notifications)
    send_notifications && ::UserMailer.perform_deliveries
  end

  def abort_sending?(send_notifications)
    !send_notification?(send_notifications) ||
      !resource.class.exists?(id: resource.id)
  end

  def user_with_fallback
    user || DeletedUser.first
  end

  def add_receiver(receivers, collection, reason)
    collection.each do |notification|
      receivers[notification.user_id][notification.channel] << reason
    end
  end

  def remove_self_recipient(receivers)
    receivers.delete(user.id) if receivers[user.id] && !user_with_fallback.pref.self_notified?
  end

  def receivers_hash
    Hash.new do |hash, user|
      hash[user] = Hash.new do |channel_hash, channel|
        channel_hash[channel] = []
      end
    end
  end

  def strategy
    @strategy ||= if self.class.const_defined?("#{resource.class}Strategy")
                    "#{self.class}::#{resource.class}Strategy".constantize
                  end
  end

  def supported?
    strategy.present?
  end

  def user
    strategy.user(resource)
  end

  def project
    strategy.project(resource)
  end
end
