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

module WorkPackageMeetingsTab
  class HeadingComponent < ApplicationComponent
    include ApplicationHelper
    include OpPrimer::ComponentHelpers
    include OpTurbo::Streamable

    def initialize(work_package:)
      super

      @work_package = work_package
    end

    def call
      component_wrapper do
        flex_layout(justify_content: :space_between, align_items: :center) do |flex|
          flex.with_column do
            info_partial
          end
          if allowed_to_add_to_meeting?
            flex.with_column(ml: 3) do
              add_to_meeting_partial
            end
          end
        end
      end
    end

    private

    def allowed_to_add_to_meeting?
      User.current.allowed_to?(:edit_meetings, @work_package.project)
    end

    def info_partial
      render(Primer::Beta::Text.new(color: :subtle)) { t("text_add_work_package_to_meeting_description") }
    end

    def add_to_meeting_partial
      # we need to render a dialog with size :xlarge as the RTE requires this size to be able to render the toolbar properly
      render(OpTurbo::OpPrimer::AsyncDialogComponent.new(
               id: "add-work-package-to-meeting-dialog",
               src: dialog_work_package_meeting_agenda_items_path(@work_package),
               size: :xlarge,
               title: t("label_add_work_package_to_meeting_dialog_title"),
               button_icon: :plus,
               button_text: t("label_add_work_package_to_meeting_dialog_button"),
               button_attributes: {
                 test_selector: "op-add-work-package-to-meeting-dialog-trigger"
               }
             ))
    end
  end
end
