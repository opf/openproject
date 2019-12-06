#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

class WatcherNotificationMailer
  class << self
    def handle_watcher_toggle(watchable, user, watcher_setter, is_watching)
      # We only handle this watcher setting if associated user wants to be notified
      # about it.
      return unless notify_about_watcher_added?(user, watcher_setter, watchable)

      unless other_jobs_queued?(watchable)
        DeliverWatcherNotificationJob.perform_later(watchable.id, user.id, watcher_setter.id, is_watching)
      end
    end

    private

    # HACK: TODO this needs generalization as well as performance improvements
    # We need to make sure no work package created or updated job is queued to avoid sending two
    # mails in short succession.
    def other_jobs_queued?(work_package)
      Delayed::Job.where('handler LIKE ?',
                         "%NotificationJob%journal_id: #{work_package.journals.last.id}%").exists?
    end

    def notify_about_watcher_added?(user, watcher_setter, watchable)
      return false if notify_about_self_watching?(user, watcher_setter)

      case user.mail_notification
      when 'only_my_events'
        true
      when 'selected'
        watching_selected_includes_project?(user, watchable)
      else
        user.notify_about?(watchable)
      end
    end

    def notify_about_self_watching?(user, watcher_setter)
      user == watcher_setter && !user.pref.self_notified?
    end

    def watching_selected_includes_project?(user, watchable)
      user.notified_projects_ids.include?(watchable.project_id)
    end
  end
end
