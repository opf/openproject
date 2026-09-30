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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Admin
  class AttachmentsSettingsHeaderComponent < ApplicationComponent
    def initialize(title:, selected:)
      raise "selected must 1, 2 or 3" if [1, 2, 3].exclude?(selected)

      @title = title
      @selected = selected
    end

    def tabs
      tabs = [
        {
          name: "general",
          path: admin_settings_attachments_path,
          label: t("settings.general")
        }
      ]

      if Setting.antivirus_scan_available?
        tabs << {
          name: "virus",
          path: admin_settings_virus_scanning_path,
          label: t(:"settings.antivirus.title"),
          enterprise_feature: :virus_scanning
        }
      end

      if Setting.antivirus_scan_available? &&
        User.current.admin? &&
        (EnterpriseToken.allows_to?(:virus_scanning) || Attachment.status_quarantined.any?)
        tabs << {
          name: "quarantined",
          path: admin_quarantined_attachments_path,
          label: t(:"antivirus_scan.quarantined_attachments.title")
        }
      end

      tabs
    end
  end
end
