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

class Notifications::JournalWpNotificationService
  MENTION_USER_ID_PATTERN =
    '<mention[^>]*(?:data-type="user"[^>]*data-id="(\d+)")|(?:data-id="(\d+)"[^>]*data-type="user")[^>]*>)|(?:\buser#(\d+)\b'
      .freeze
  MENTION_USER_LOGIN_PATTERN =
    '\buser:"(.+?)"'.freeze
  MENTION_GROUP_ID_PATTERN =
    '<mention[^>]*(?:data-type="group"[^>]*data-id="(\d+)")|(?:data-id="(\d+)"[^>]*data-type="group")[^>]*>)|(?:\bgroup#(\d+)\b'
      .freeze
  MENTION_PATTERN = Regexp.new("(?:#{MENTION_USER_ID_PATTERN})|(?:#{MENTION_USER_LOGIN_PATTERN})|(?:#{MENTION_GROUP_ID_PATTERN})")

  class << self
    def call(journal, send_notifications)
      return nil if abort_sending?(journal, send_notifications)

      author = User.find_by(id: journal.user_id) || DeletedUser.first

      notification_receivers(journal.journable, journal).each do |recipient_id, channel_reasons|
        create_event(journal,
                     recipient_id,
                     channel_reasons.keys,
                     # TODO: split up into two separate reasons
                     # For now, we prepare the in_app reason since that one is displayed.
                     channel_reasons['in_app'].first || channel_reasons['mail'].first,
                     author)
      end
    end

    private

    def create_event(journal, recipient_id, channels, reason, user)
      notification_attributes = {
        recipient_id: recipient_id,
        reason: reason,
        project: journal.project,
        resource: journal.journable,
        journal: journal,
        actor: journal.user
      }.merge(channel_attributes(channels))

      Notifications::CreateService
        .new(user: user)
        .call(notification_attributes)
    end

    def channel_attributes(channels)
      {
        read_email: channels.include?('mail') ? false : nil,
        read_ian: channels.include?('in_app') ? false : nil

      }
    end

    def notification_receivers(work_package, journal)
      receivers = receivers_hash

      add_receiver(receivers, mentioned(journal), :mentioned)
      add_receiver(receivers, involved(journal), :involved)
      add_receiver(receivers, watched(work_package), :watched)
      add_receiver(receivers, subscribed(journal), :subscribed)

      receivers
    end

    def mentioned(journal)
      allowed_and_unique(mentioned_ids(journal),
                         journal.data.project,
                         :mentioned)
    end

    def involved(journal)
      scope = User
        .where(id: group_or_user_ids(journal.data.assigned_to))
        .or(User.where(id: group_or_user_ids(journal.data.responsible)))

      allowed_and_unique(scope,
                         journal.data.project,
                         :involved)
    end

    def subscribed(journal)
      project = journal.data.project

      allowed_and_unique(User.notified_on_all(project),
                         project,
                         :all)
    end

    def watched(work_package)
      allowed_and_unique(work_package.watcher_users,
                         work_package.project,
                         :watched)
    end

    def allowed_and_unique(user_scope, project, reason)
      NotificationSetting
        .applicable(project)
        .where(reason => true)
        .where(user: user_scope.where(id: User.allowed(:view_work_packages, project)))
    end

    def text_for_mentions(journal)
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

    def mentioned_ids(journal)
      matches = mention_matches(journal)

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

    def send_notification?(journal, send_notifications)
      send_notifications && ::UserMailer.perform_deliveries && send_notification_setting?(journal)
    end

    def send_notification_setting?(journal)
      notify_for_wp_added?(journal) ||
        notify_for_wp_updated?(journal) ||
        notify_for_notes?(journal) ||
        notify_for_status?(journal) ||
        notify_for_priority(journal)
    end

    def mention_matches(journal)
      text = text_for_mentions(journal)

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

    def notify_for_wp_added?(journal)
      notification_enabled?('work_package_added') && journal.initial?
    end

    def notify_for_wp_updated?(journal)
      notification_enabled?('work_package_updated') && !journal.initial?
    end

    def notify_for_notes?(journal)
      notification_enabled?('work_package_note_added') && journal.notes.present?
    end

    def notify_for_status?(journal)
      notification_enabled?('status_updated') &&
        journal.details.has_key?(:status_id)
    end

    def notify_for_priority(journal)
      notification_enabled?('work_package_priority_updated') &&
        journal.details.has_key?(:priority_id)
    end

    def notification_enabled?(name)
      Setting.notified_events.include?(name)
    end

    def abort_sending?(journal, send_notifications)
      !send_notification?(journal, send_notifications) || journal.noop?
    end

    def group_or_user_ids(association)
      association.is_a?(Group) ? association.user_ids : association&.id
    end

    def add_receiver(receivers, collection, reason)
      collection.each do |notification|
        receivers[notification.user_id][notification.channel] << reason
      end
    end

    def receivers_hash
      Hash.new do |hash, user|
        hash[user] = Hash.new do |channel_hash, channel|
          channel_hash[channel] = []
        end
      end
    end
  end
end
