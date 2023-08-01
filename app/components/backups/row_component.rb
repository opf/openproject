# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

module Backups
  class RowComponent < ::RowComponent
    property :comment, :size_in_mb, :creator, :created_at, :status

    def backup
      model
    end

    def comment # rubocop:disable Rails/Delegate
      backup.comment
    end

    def size_in_mb
      backup.size_in_mb || 0
    end

    def created_at
      helpers.format_time backup.created_at
    end

    def creator
      backup.creator.name
    end

    def status
      status = backup.job_status&.status.presence

      if status
        I18n.t("backup.job_status.#{status}")
      else
        "?"
      end
    end

    def button_links
      if backup.ready?
        ready_links + default_links
      else
        default_links
      end
    end

    def default_links
      [helpers.link_to("Delete", admin_backup_path(backup.id), method: :delete, class: "icon icon-delete")]
    end

    def ready_links
      ready = [helpers.link_to("Download", "/attachments/#{backup.attachments.first.id}", class: "icon icon-download")]

      ready + restore_links
    end

    def restore_links
      return [] unless Setting.restore_backup_enabled?

      [
        helpers.link_to("Preview", preview_admin_backup_path(backup.id), class: "icon icon-watched"),
        helpers.link_to("Restore", restore_admin_backup_path(backup.id), class: "icon icon-import")
      ]
    end
  end
end
