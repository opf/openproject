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
module IncomingEmails::Handlers
  class WorkPackage < Base
    # Contract classes for handlers to use
    class UpdateWorkPackageWithoutAuthorizationsContract < WorkPackages::UpdateContract
      include WorkPackages::SkipAuthorizationChecks
    end

    class CreateWorkPackageWithoutAuthorizationsContract < WorkPackages::CreateContract
      include WorkPackages::SkipAuthorizationChecks
    end

    def self.handles?(_email, reference:, automated_email:)
      return false if automated_email

      # Handle work package replies if there's a references match
      # And handle defaults
      reference[:klass].nil? || %w[work_package journal].include?(reference[:klass])
    end

    def process
      case reference[:klass]
      when "work_package"
        receive_work_package_reply(reference[:id])
      when "journal"
        receive_journal_reply(reference[:id])
      else
        # Default: create new work package
        receive_new_work_package
      end
    end

    private

    def receive_journal_reply(journal_id)
      journal = Journal.find_by(id: journal_id)
      return unless journal

      if journal.journable_type == "WorkPackage"
        receive_work_package_reply(journal.journable_id)
      end
    end

    # Creates a new work package
    def receive_new_work_package
      project = target_project

      call = create_work_package(project)

      call.message =
        if call.success?
          "work_package created by #{user}"
        else
          "work_package could not be created by #{user} due to ##{call.errors.full_messages}"
        end

      call
    end

    # Adds a note to an existing work package
    def receive_work_package_reply(work_package_id) # rubocop:disable Metrics/AbcSize
      work_package = ::WorkPackage.find_by(id: work_package_id)
      return unless work_package

      # ignore CLI-supplied defaults for new work_packages
      options[:issue].clear

      call = update_work_package(work_package)
      if call.success?
        ServiceResult.success(
          result: call.result.last_journal,
          message: "work_package ##{work_package.id} updated by #{user}"
        )
      else
        ServiceResult.failure(
          result: call.result,
          message: "work_package ##{work_package.id} could not be updated by #{user} due to ##{call.errors.full_messages}"
        )
      end
    end

    def create_work_package(project)
      work_package = ::WorkPackage.new(project:)
      attributes = collect_wp_attributes_from_email_on_create(work_package)

      service_call = WorkPackages::CreateService
        .new(user: user,
             contract_class: work_package_create_contract_class)
        .call(**attributes.merge(work_package:).symbolize_keys)

      service_call.on_success do
        work_package = service_call.result

        add_watchers(work_package)
        add_attachments(work_package)
      end
    end

    def collect_wp_attributes_from_email_on_create(work_package)
      attributes = wp_attributes_from_keywords(work_package)
      attributes
        .merge("custom_field_values" => custom_field_values_from_keywords(work_package),
               "subject" => email.subject.to_s.chomp[0, 255] || "(no subject)",
               "description" => cleaned_up_text_body)
    end

    def update_work_package(work_package)
      attributes = collect_wp_attributes_from_email_on_update(work_package)
      attributes[:attachment_ids] = work_package.attachment_ids + add_attachments(work_package).map(&:id)

      WorkPackages::UpdateService
        .new(user: user,
             model: work_package,
             contract_class: work_package_update_contract_class)
        .call(**attributes.symbolize_keys)
    end

    def collect_wp_attributes_from_email_on_update(work_package)
      attributes = wp_attributes_from_keywords(work_package)
      attributes
        .merge("custom_field_values" => custom_field_values_from_keywords(work_package),
               "journal_notes" => cleaned_up_text_body)
    end

    # Returns a Hash of issue attributes extracted from keywords in the email body
    def wp_attributes_from_keywords(work_package)
      {
        "assigned_to_id" => wp_assignee_from_keywords(work_package),
        "category_id" => wp_category_from_keywords(work_package),
        "due_date" => wp_due_date_from_keywords,
        "estimated_hours" => wp_estimated_hours_from_keywords,
        "parent_id" => wp_parent_from_keywords,
        "priority_id" => wp_priority_from_keywords,
        "remaining_hours" => wp_remaining_hours_from_keywords,
        "responsible_id" => wp_accountable_from_keywords(work_package),
        "start_date" => wp_start_date_from_keywords,
        "status_id" => wp_status_from_keywords,
        "type_id" => wp_type_from_keywords(work_package),
        "version_id" => wp_version_from_keywords(work_package)
      }.compact_blank!
    end

    def wp_type_from_keywords(work_package)
      lookup_case_insensitive_key(work_package.project.types, :type) ||
        (work_package.new_record? && work_package.project.types.first.try(:id))
    end

    def wp_status_from_keywords
      lookup_case_insensitive_key(Status, :status)
    end

    def wp_parent_from_keywords
      get_keyword(:parent)
    end

    def wp_priority_from_keywords
      lookup_case_insensitive_key(IssuePriority, :priority)
    end

    def wp_category_from_keywords(work_package)
      lookup_case_insensitive_key(work_package.project.categories, :category)
    end

    def wp_accountable_from_keywords(work_package)
      get_assignable_principal_from_keywords(:responsible, work_package)
    end

    def wp_assignee_from_keywords(work_package)
      get_assignable_principal_from_keywords(:assigned_to, work_package)
    end

    def get_assignable_principal_from_keywords(keyword, work_package)
      keyword = get_keyword(keyword, override: true)

      return nil if keyword.blank?

      Principal.possible_assignee(work_package.project).where(id: Principal.like(keyword)).first.try(:id)
    end

    def wp_version_from_keywords(work_package)
      lookup_case_insensitive_key(work_package.project.shared_versions, :version, Arel.sql("#{Version.table_name}.name"))
    end

    def wp_start_date_from_keywords
      get_keyword(:start_date, override: true, format: '\d{4}-\d{2}-\d{2}')
    end

    def wp_due_date_from_keywords
      get_keyword(:due_date, override: true, format: '\d{4}-\d{2}-\d{2}')
    end

    def wp_estimated_hours_from_keywords
      get_keyword(:estimated_hours, override: true)
    end

    def wp_remaining_hours_from_keywords
      get_keyword(:remaining_hours, override: true)
    end

    def work_package_create_contract_class
      if options[:no_permission_check]
        CreateWorkPackageWithoutAuthorizationsContract
      else
        WorkPackages::CreateContract
      end
    end

    def work_package_update_contract_class
      if options[:no_permission_check]
        UpdateWorkPackageWithoutAuthorizationsContract
      else
        WorkPackages::UpdateContract
      end
    end
  end
end
