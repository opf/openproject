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

module Import
  class JiraCreateProjectWorkPackageAttachmentsJob < ProgressableJob
    def text
      jira_project_name = Import::JiraProject.find(arguments[1]).payload["name"]
      "Download work package attachments for '#{jira_project_name}'"
    end

    def percentage
      jira_import = Import::JiraImport.find(arguments[0])
      cursor = jira_import.get_job_cursor(self)
      if cursor.present?
        issues = Import::JiraIssue.where(jira_import:, jira_project_id: arguments[1])
        total = issues.count
        position = issues.where(id: ..cursor).count
        (position.to_f / total * 100).round(2)
      else
        0
      end
    end

    # rubocop:disable Metrics/AbcSize
    def build_enumerator(jira_import_id, jira_project_id, cursor:)
      @jira_import = Import::JiraImport.find(jira_import_id)
      jira = @jira_import.jira
      @jira_id = jira.id
      @system_user = User.system
      @jira_client = Import::JiraClient.new(url: jira.url, personal_access_token: jira.personal_access_token)
      jira_project = Import::JiraProject.find(jira_project_id)

      @project_role = Role.find_by!(name: "JiraMember")

      @project = JiraOpenProjectReference.find_by!(
        jira_entity_id: jira_project.id,
        jira_entity_class: jira_project.class.to_s
      ).op_leg

      cursor ||= @jira_import.get_job_cursor(self)
      enumerator_builder.active_record_on_records(
        Import::JiraIssue.where(jira_import_id:, jira_project_id:),
        cursor: cursor
      )
    end
    # rubocop:enable Metrics/AbcSize

    # rubocop:disable Metrics/AbcSize
    def each_iteration(jira_issue, _jira_import_id, _jira_project_id)
      Journal::NotificationConfiguration.with(false) do
        Journal::EventConfiguration.with(false) do
          work_package = JiraOpenProjectReference.find_by!(
            jira_entity_id: jira_issue.id,
            jira_entity_class: jira_issue.class.to_s
          ).op_leg
          attachments = jira_issue.payload.dig("fields", "attachment") || []
          attachments.each do |attachment|
            key = attachment.dig("author", "key")
            author = find_user(key)
            create_member(@project, author) if author.present?
            create_attachment(work_package, attachment, author || User.system)
          end
        end
      end
    end
    # rubocop:enable Metrics/AbcSize

    private

    def create_attachment(work_package, attachment, author)
      filename = attachment["filename"]
      content_url = attachment["content"]
      mime_type = attachment["mimeType"]
      size = attachment["size"]
      @jira_client.download_attachment(content_url, filename) do |tempfile|
        tempfile.rewind
        tempfile.define_singleton_method(:original_filename) { filename }
        tempfile.define_singleton_method(:content_type) { mime_type }
        tempfile.define_singleton_method(:size) { size }
        call = Attachments::CreateService
                 .new(user: author, contract_class: EmptyContract)
                 .call(container: work_package, filename:, file: tempfile)

        call.on_failure do
          raise call.message
        end
      end
    end

    def create_member(project, member)
      service_call = Members::CreateService
                       .new(user: @system_user, contract_class: EmptyContract)
                       .call(
                         project:,
                         roles: [@project_role],
                         user_id: member.id,
                         principal: member
                       )
      return if service_call.success?

      if service_call.errors.find { |error| error.type == :taken }.blank?
        raise service_call.message
      end
    end

    def find_user(jira_user_key)
      return if jira_user_key.blank?

      jira_user = Import::JiraUser.find_by(origin_id: jira_user_key, jira_import: @jira_import)
      if jira_user
        ref = JiraOpenProjectReference.find_by(
          jira_entity_class: "Import::JiraUser",
          jira_entity_id: jira_user.id
        )
        if ref.present?
          ref.op_leg
        else
          raise "Reference was expected to be found, but it was not. JiraUser: #{jira_user.inspect}"
        end
      else
        raise "Import::JiraUser with jira_user_key #{jira_user_key} not found!"
      end
    end
  end
end
