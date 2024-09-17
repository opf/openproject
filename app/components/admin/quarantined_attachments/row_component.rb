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

module Admin
  module QuarantinedAttachments
    class RowComponent < ::RowComponent
      delegate :project, to: :attachment, allow_nil: true
      delegate :container, to: :attachment, allow_nil: true

      def attachment
        model
      end

      def row_css_id
        "quarantined_attachment_#{attachment.id}"
      end

      delegate :filename, to: :attachment

      def attached_to
        description = attachment.description.present? ? "(#{attachment.description})" : ""
        text = "#{container_name} #{attachment.container_id} #{description}"
        case container
        when Message
          helpers.link_to_message(container)
        when WorkPackage
          helpers.link_to_work_package(container)
        when WikiPage
          helpers.link_to(text, project_wiki_path(project, container))
        when User
          helpers.link_to_user(container)
        when MeetingContent
          helpers.link_to(text, meeting_path(container.meeting_id))
        when Grids::Overview
          helpers.link_to(text, project_overview_path(container.project_id))
        else
          text
        end
      end

      def container_name
        container ? container.model_name.human : (attachment.container_type || I18n.t(:label_none))
      end

      def author
        render Users::AvatarComponent.new(user: attachment.author, size: :mini, link: true, show_name: true)
      end

      def created_at
        helpers.format_time attachment.created_at
      end

      def button_links
        [delete_link]
      end

      def delete_link
        helpers.link_to(
          helpers.op_icon("icon icon-delete"),
          { controller: "/admin/attachments/quarantined_attachments", action: :destroy, id: model },
          title: I18n.t("antivirus_scan.quarantined_attachments.delete"),
          method: :delete,
          data: { confirm: I18n.t(:text_are_you_sure), disable_with: I18n.t(:label_loading) }
        )
      end
    end
  end
end
