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
module Projects::Settings::WorkPackages::Activities
  class Form < ApplicationForm
    form do |f|
      f.check_box(
        name: :enabled_internal_comments,
        label: I18n.t("settings.work_packages.activities.enable_internal_comments"),
        caption: caption_text,
        checked: model.project.enabled_internal_comments
      )

      f.submit(
        name: :submit,
        label: I18n.t(:button_save),
        scheme: :primary
      )
    end

    def initialize(**_options)
      super()
    end

    private

    def caption_text
      helpers.link_translate("settings.work_packages.activities.helper_text_html",
                             links: { docs_url: %i[enterprise_features internal_comments] })
    end
  end
end
