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
    def handle_watcher(watcher, watcher_setter)
      # We only handle this watcher setting if associated user wants to be notified
      # about it.
      return unless notify_about_watcher_added?(watcher, watcher_setter)

      unless other_jobs_queued?(watcher.watchable)
        job = DeliverWatcherNotificationJob.new(watcher.id, watcher.user.id, watcher_setter.id)
        Delayed::Job.enqueue job, priority: ::ApplicationJob.priority_number(:notification)
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

    def notify_about_watcher_added?(watcher, watcher_setter)
      return false if notify_about_self_watching?(watcher, watcher_setter)

      case watcher.user.mail_notification
      when 'only_my_events'
        true
      when 'selected'
        watching_selected_includes_project?(watcher)
      else
        watcher.user.notify_about?(watcher.watchable)
      end
    end

    def notify_about_self_watching?(watcher, watcher_setter)
      watcher.user == watcher_setter && !watcher.user.pref.self_notified?
    end

    def watching_selected_includes_project?(watcher)
      watcher.user.notified_projects_ids.include?(watcher.watchable.project_id)
    end
  end
end
