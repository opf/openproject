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

class Notifications::CreateFromModelService
  MENTION_USER_ID_PATTERN =
    '<mention[^>]*(?:data-type="user"[^>]*data-id="(\d+)")|(?:data-id="(\d+)"[^>]*data-type="user")[^>]*>)|(?:\buser#(\d+)\b'
      .freeze
  MENTION_USER_LOGIN_PATTERN =
    '\buser:"(.+?)"'.freeze
  MENTION_GROUP_ID_PATTERN =
    '<mention[^>]*(?:data-type="group"[^>]*data-id="(\d+)")|(?:data-id="(\d+)"[^>]*data-type="group")[^>]*>)|(?:\bgroup#(\d+)\b'
      .freeze
  MENTION_PATTERN = Regexp.new("(?:#{MENTION_USER_ID_PATTERN})|(?:#{MENTION_USER_LOGIN_PATTERN})|(?:#{MENTION_GROUP_ID_PATTERN})")

  def initialize(model)
    self.model = model
  end

  def call(send_notifications)
    result = ServiceResult.new success: !abort_sending?(send_notifications)

    return result if result.failure?

    notification_receivers.each do |recipient_id, channel_reasons|
      call = create_notification(recipient_id, channel_reasons)
      result.add_dependent!(call)
    end

    result
  end

  private

  attr_accessor :model

  def create_notification(recipient_id, channel_reasons)
    notification_attributes = {
      recipient_id: recipient_id,
      project: project,
      resource: resource,
      journal: journal,
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

  def settings_of_mentioned
    applicable_settings(mentioned_ids,
                        project,
                        :mentioned)
  end

  def settings_of_involved
    scope = User
              .where(id: group_or_user_ids(journal.data.assigned_to))
              .or(User.where(id: group_or_user_ids(journal.data.responsible)))

    applicable_settings(scope,
                        project,
                        :involved)
  end

  def settings_of_subscribed
    applicable_settings(strategy.subscribed_users(model),
                        project,
                        :all)
  end

  def settings_of_watched
    applicable_settings(strategy.watcher_users(model),
                        project,
                        :watched)
  end

  def settings_of_commented
    return NotificationSetting.none unless journal.notes?

    applicable_settings(User.all,
                        project,
                        :work_package_commented)
  end

  def settings_of_created
    return NotificationSetting.none unless journal.initial?

    applicable_settings(User.all,
                        project,
                        :work_package_created)
  end

  def settings_of_processed
    return NotificationSetting.none unless !journal.initial? && journal.details.has_key?(:status_id)

    applicable_settings(User.all,
                        project,
                        :work_package_processed)
  end

  def settings_of_prioritized
    return NotificationSetting.none unless !journal.initial? && journal.details.has_key?(:priority_id)

    applicable_settings(User.all,
                        project,
                        :work_package_prioritized)
  end

  def settings_of_scheduled
    if journal.initial? || !(journal.details.has_key?(:start_date) || journal.details.has_key?(:due_date))
      return NotificationSetting.none
    end

    applicable_settings(User.all,
                        project,
                        :work_package_scheduled)
  end

  def applicable_settings(user_scope, project, reason)
    NotificationSetting
      .applicable(project)
      .where(reason => true)
      .where(user: user_scope.where(id: User.allowed(strategy.permission, project)))
  end

  def text_for_mentions
    potential_text = ""
    potential_text << journal.notes if journal.try(:notes)

    %i[description subject].each do |field|
      details = journal.details[field]

      if details.present?
        potential_text << "\n#{Redmine::Helpers::Diff.new(*details.reverse).additions.join(' ')}"
      end
    end
    potential_text
  end

  def mentioned_ids
    matches = mention_matches

    base_scope = User
                   .includes(:groups)
                   .references(:groups_users)

    by_id = base_scope.where(id: matches[:user_ids])
    by_login = base_scope.where(login: matches[:user_login_names])
    by_group = base_scope.where(groups_users: { id: matches[:group_ids] })

    by_id
      .or(by_login)
      .or(by_group)
  end

  def send_notification?(send_notifications)
    send_notifications && ::UserMailer.perform_deliveries
  end

  def mention_matches
    text = text_for_mentions

    user_ids_tag_after,
      user_ids_tag_before,
      user_ids_hash,
      user_login_names,
      group_ids_tag_after,
      group_ids_tag_before,
      group_ids_hash = text
                         .scan(MENTION_PATTERN)
                         .transpose
                         .each(&:compact!)

    {
      user_ids: [user_ids_tag_after, user_ids_tag_before, user_ids_hash].flatten.compact,
      user_login_names: [user_login_names].flatten.compact,
      group_ids: [group_ids_tag_after, group_ids_tag_before, group_ids_hash].flatten.compact
    }
  end

  def abort_sending?(send_notifications)
    !send_notification?(send_notifications) ||
      model.nil? ||
      !model.class.exists?(id: model.id) ||
      journal&.noop? ||
      !supported?
  end

  def group_or_user_ids(association)
    association.is_a?(Group) ? association.user_ids : association&.id
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
    receivers.delete(user_with_fallback.id)
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
    strategy.user(model)
  end

  def project
    strategy.project(model)
  end

  def resource
    model.is_a?(Journal) ? model.journable : model
  end

  def journal
    model.is_a?(Journal) ? model : nil
  end
end
