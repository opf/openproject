# frozen_string_literal: true

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

module Admin
  module QuarantinedAttachments
    class RowComponent < ::RowComponent
      def attachment
        model
      end

      def row_css_id
        "quarantined_attachment_#{attachment.id}"
      end

      def filename
        attachment.filename
      end

      def container
        "#{attachment.container_type} ##{attachment.container_id}"
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
          helpers.op_icon('icon icon-delete'),
          { controller: '/admin/attachments/quarantined_attachments', action: :destroy, id: model },
          method: :delete,
          data: { confirm: I18n.t(:text_are_you_sure), disable_with: I18n.t(:label_loading) },
        )
      end
    end
  end
end
