#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module UserPreferences
  class UpdateService < ::BaseServices::Update
    protected

    attr_accessor :notifications

    def validate_params(params)
      contract = ParamsContract.new(model, user, params:)

      ServiceResult.new success: contract.valid?,
                        errors: contract.errors,
                        result: model
    end

    def before_perform(params, _service_result)
      self.notifications = params&.delete(:notification_settings)

      super
    end

    def after_perform(service_call)
      return service_call if notifications.nil?

      inserted = persist_notifications
      remove_other_notifications(inserted)

      service_call
    end

    def persist_notifications
      global, project = notifications
                          .map { |item| item.merge(user_id: model.user_id) }
                          .partition { |setting| setting[:project_id].nil? }

      global_ids = upsert_notifications(global, %i[user_id], 'project_id IS NULL')
      project_ids = upsert_notifications(project, %i[user_id project_id], 'project_id IS NOT NULL')

      global_ids + project_ids
    end

    def remove_other_notifications(ids)
      NotificationSetting
        .where(user_id: model.user_id)
        .where.not(id: ids)
        .delete_all
    end

    ##
    # Upsert notification while respecting the partial index on notification_settings
    # depending on the project presence
    #
    # @param notifications The array of notification hashes to upsert
    # @param conflict_target The uniqueness constraint to upsert within
    # @param index_predicate The partial index condition on the project
    def upsert_notifications(notifications, conflict_target, index_predicate)
      return [] if notifications.empty?

      NotificationSetting
        .import(
          notifications,
          on_duplicate_key_update: {
            conflict_target:,
            index_predicate:,
            columns: %i[watched
                        assignee
                        responsible
                        shared
                        mentioned
                        start_date
                        due_date
                        overdue
                        work_package_commented
                        work_package_created
                        work_package_processed
                        work_package_prioritized
                        work_package_scheduled
                        news_added
                        news_commented
                        document_added
                        forum_messages
                        wiki_page_added
                        wiki_page_updated
                        membership_added
                        membership_updated]
          },
          validate: false
        ).ids
    end
  end
end
