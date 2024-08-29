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

class Notifications::CreateFromModelService
  MENTION_USER_TAG_ID_PATTERN =
    '<mention[^>]*(?:data-type="user"[^>]*data-id="(\d+)")|(?:data-id="(\d+)"[^>]*data-type="user")[^>]*>'
      .freeze
  MENTION_USER_HASH_ID_PATTERN =
    '\buser#(\d+)\b'
      .freeze
  MENTION_USER_LOGIN_PATTERN =
    '\buser:"(.+?)"'.freeze
  MENTION_GROUP_TAG_ID_PATTERN =
    '<mention[^>]*(?:data-type="group"[^>]*data-id="(\d+)")|(?:data-id="(\d+)"[^>]*data-type="group")[^>]*>'
      .freeze
  MENTION_GROUP_HASH_ID_PATTERN =
    '\bgroup#(\d+)\b'
      .freeze
  COMBINED_MENTION_PATTERN =
    [MENTION_USER_TAG_ID_PATTERN,
     MENTION_USER_HASH_ID_PATTERN,
     MENTION_USER_LOGIN_PATTERN,
     MENTION_GROUP_TAG_ID_PATTERN,
     MENTION_GROUP_HASH_ID_PATTERN]
      .map { |pattern| "(?:#{pattern})" }
      .join("|").freeze

  # Skip looking for mentions in quoted lines completely.
  # We need to allow an optional single white space before the ">", because the `#text_for_mentions`
  # method appends a white space to the journal details. With the notes it's not the case.
  QUOTED_LINES_PATTERN = /^ ?> .*$/
  MENTION_PATTERN = Regexp.new(COMBINED_MENTION_PATTERN)

  def initialize(model)
    self.model = model
  end

  # Creates Notifications according to the various settings:
  #
  # * configured by the individual users
  # * the send_notifications property provided
  #
  # and also by the properties of the journal, e.g.:
  #
  # * a work package mentioning a user
  # * a news begin watched
  #
  # This method might be called multiple times, mostly when a journal is
  # aggregated. On the second run, the potentially existing Notifications need
  # to be taken into account by
  #
  # * updating them if the user is still to be notified: resetting the read_ian
  #   to false if the strategy supports ian
  # * destroying them if the user is no longer to be notified
  def call(send_notifications)
    result = ServiceResult.new success: !abort_sending?

    return result if result.failure?

    current_notifications = notification_receivers(send_notifications).transform_values(&:first)

    current_notifications.each do |recipient_id, reason|
      result.add_dependent!(update_or_create_notification(recipient_id, reason))
    end

    delete_outdated_notifications(current_notifications.keys)

    result
  end

  private

  attr_accessor :model

  # In case a notification already exists (because the journal was aggregated)
  # an existing notification is updated
  def update_or_create_notification(recipient_id, reason)
    update_notification(recipient_id, reason) or create_notification(recipient_id, reason)
  end

  def create_notification(recipient_id, reason)
    notification_attributes = {
      recipient_id:,
      resource:,
      journal:,
      actor: user_with_fallback,
      reason:,
      read_ian: strategy.supports_ian?(reason) ? false : nil,
      mail_reminder_sent: strategy.supports_mail_digest?(reason) ? false : nil,
      mail_alert_sent: strategy.supports_mail?(reason) ? false : nil
    }

    Notifications::CreateService
      .new(user: user_with_fallback)
      .call(notification_attributes)
  end

  def update_notification(recipient_id, reason)
    existing_notification = Notification
                              .find_by(resource:, journal:, recipient_id:)

    return unless existing_notification

    Notifications::UpdateService
      .new(model: existing_notification, user:, contract_class: EmptyContract)
      .call(read_ian: strategy.supports_ian?(reason) ? false : nil,
            reason:)
  end

  def delete_outdated_notifications(current_recipient_ids)
    Notification
      .where(journal:)
      .where.not(recipient_id: current_recipient_ids)
      .destroy_all
  end

  def notification_receivers(send_notifications)
    receivers = receivers_hash

    return receivers unless send_notification?(send_notifications)

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
    project_applicable_settings(mentioned_ids,
                                project,
                                NotificationSetting::MENTIONED)
  end

  def settings_of_assigned
    project_applicable_settings(User.where(id: group_or_user_ids(journal.data.assigned_to)),
                                project,
                                NotificationSetting::ASSIGNEE)
  end

  def settings_of_responsible
    project_applicable_settings(User.where(id: group_or_user_ids(journal.data.responsible)),
                                project,
                                NotificationSetting::RESPONSIBLE)
  end

  def settings_of_shared
    project_applicable_settings(strategy.shared_users(model),
                                project,
                                NotificationSetting::SHARED)
  end

  def settings_of_subscribed
    # Subscribed is a collection of events for non-work packages
    # which currently ignore project-specific overrides
    settings_for_allowed_users(strategy.subscribed_users(model),
                               strategy.subscribed_notification_reason(model))
  end

  def settings_of_watched
    project_applicable_settings(strategy.watcher_users(model),
                                project,
                                NotificationSetting::WATCHED)
  end

  def settings_of_commented
    return NotificationSetting.none unless journal.notes?

    project_applicable_settings(User.all,
                                project,
                                NotificationSetting::WORK_PACKAGE_COMMENTED)
  end

  def settings_of_created
    return NotificationSetting.none unless journal.initial?

    project_applicable_settings(User.all,
                                project,
                                NotificationSetting::WORK_PACKAGE_CREATED)
  end

  def settings_of_processed
    return NotificationSetting.none unless !journal.initial? && journal.details.has_key?(:status_id)

    project_applicable_settings(User.all,
                                project,
                                NotificationSetting::WORK_PACKAGE_PROCESSED)
  end

  def settings_of_prioritized
    return NotificationSetting.none unless !journal.initial? && journal.details.has_key?(:priority_id)

    project_applicable_settings(User.all,
                                project,
                                NotificationSetting::WORK_PACKAGE_PRIORITIZED)
  end

  def settings_of_scheduled
    if journal.initial? || !(journal.details.has_key?(:start_date) || journal.details.has_key?(:due_date))
      return NotificationSetting.none
    end

    project_applicable_settings(User.all,
                                project,
                                NotificationSetting::WORK_PACKAGE_SCHEDULED)
  end

  def project_applicable_settings(user_scope, project, reason)
    settings_for_allowed_users(user_scope, reason)
      .applicable(project)
  end

  def settings_for_allowed_users(user_scope, reason)
    NotificationSetting
      .where(reason => true)
      .where(user: user_scope.where(id: User.allowed(strategy.permission, project)))
  end

  # Returns the text of the model (currently suited to work package description and subject) eligible
  # to be looked at for mentions of users and groups:
  # * only lines added
  # * excluding quoted lines
  def text_for_mentions
    potential_text = ""
    potential_text << journal.notes if journal.try(:notes)

    %i[description subject].each do |field|
      details = journal.details[field]

      if details.present?
        potential_text << "\n#{Redmine::Helpers::Diff.new(*details.reverse).additions.join(' ')}"
      end
    end

    potential_text.gsub(QUOTED_LINES_PATTERN, "")
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
    @mention_matches ||= begin
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
  end

  def abort_sending?
    model.nil? ||
      !model.class.exists?(id: model.id) ||
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
      receivers[notification.user_id] << reason
    end
  end

  def user_not_mentioned_or_mentioned_indirectly(self_reason)
    self_reason != NotificationSetting::MENTIONED ||
    (mention_matches[:user_ids].exclude?(user_with_fallback.id) &&
     mention_matches[:user_login_names].exclude?(user_with_fallback.login))
  end

  def remove_self_recipient(receivers)
    if receivers.key?(user_with_fallback.id)
      self_reasons = receivers[user_with_fallback.id]
      self_reasons.delete_if { |reason| user_not_mentioned_or_mentioned_indirectly(reason) }
      if self_reasons.empty?
        receivers.delete(user_with_fallback.id)
      end
    end
  end

  def receivers_hash
    Hash.new do |hash, user|
      hash[user] = []
    end
  end

  def strategy
    @strategy ||= if self.class.const_defined?(:"#{resource.class}Strategy")
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
