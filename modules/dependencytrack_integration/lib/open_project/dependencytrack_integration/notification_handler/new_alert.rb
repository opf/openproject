#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2021 Ben Tey
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
# Copyright (C) 2012-2021 the OpenProject GmbH
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

module OpenProject::DependencytrackIntegration
  module NotificationHandler
    ##
    # Handles Gitlab issue notifications.
    class NewAlert
      include OpenProject::DependencytrackIntegration::NotificationHandler::Helper
      
      def process(payload_params)
        @payload = wrap_payload(payload_params)
        user = User.find_by_id(payload.open_project_user_id)
        subject_text = payload.notification.title
        if payload.notification.group == 'NEW_VULNERABILITY'
          vuln_text = "<il>#{payload.notification.subject.vulnerability.vulnId} — #{payload.notification.subject.vulnerability.description}</il>"
        else
          payload.notification.subject.vulnerabilities.each do |vuln_params|
            # Rails.logger.info "VULNERABILITY INFO 1: #{vuln_params}"
            vuln_id = vuln_params['vulnId']
            vuln_desc = vuln_params['description']
            vuln_text = "<li>#{vuln_id} — #{vuln_desc}</li>"
          end
        end

        description_text = "#{payload.notification.content}:<ul><li><b>Project:</b> #{payload.notification.subject.project.name}</li><li><b>Component:</b> #{payload.notification.subject.component.name} v#{payload.notification.subject.component.version}</li><li><b>Vulnerabilities:</b></li><ul>#{vuln_text}</ul></li></ul>"

        # Rails.logger.info "VULNERABILITY INFO 2: #{payload.notification.subject.vulnerabilities}"
        create_call = WorkPackages::CreateService
          .new(user: user)
          .call(project_id: 3, type_id: 8, subject: subject_text, description: description_text)

        if create_call.success?
          Rails.logger.info "WORKPACKAGE Created"
        else
          Rails.logger.info "WORKPACKAGE Not Created #{create_call.errors.full_messages}"
        end
      end

      private

      attr_reader :payload

      # def generate_notes(payload)
      #   accepted_actions = %w[open reopen close]

      #   key_action = {
      #     'open' => 'opened',
      #     'reopen' => 'reopened',
      #     'close' => 'closed'
      #   }[payload.object_attributes.action]

      #   return nil unless accepted_actions.include? payload.object_attributes.action
      #   I18n.t("gitlab_integration.issue_#{key_action}_referenced_comment",
      #     :issue_number => payload.object_attributes.iid,
      #     :issue_title => payload.object_attributes.title,
      #     :issue_url => payload.object_attributes.url,
      #     :repository => payload.repository.name,
      #     :repository_url => payload.repository.homepage,
      #     :gitlab_user => payload.user.name,
      #     :gitlab_user_url => payload.user.avatar_url)
      # end
    end
  end
end