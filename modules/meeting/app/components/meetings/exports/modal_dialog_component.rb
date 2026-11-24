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

module Meetings
  module Exports
    class ModalDialogComponent < ApplicationComponent
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers

      MODAL_ID = "op-meeting-export-pdf-dialog"
      MEETING_PDF_EXPORT_FORM_ID = "op-meeting-pdf-export-dialog-form"

      attr_reader :meeting, :project

      def initialize(meeting:, project:)
        super

        @meeting = meeting
        @project = project
      end

      def templates_options
        [
          {
            id: "default",
            label: I18n.t("meeting.export_pdf_dialog.templates.default.label"),
            caption: I18n.t("meeting.export_pdf_dialog.templates.default.caption")
          },
          {
            id: "minutes",
            label: I18n.t("meeting.export_pdf_dialog.templates.minutes.label"),
            caption: I18n.t("meeting.export_pdf_dialog.templates.minutes.caption")
          }
        ]
      end

      def templates_default
        templates_options[0]
      end

      def default_footer_text
        @project.name
      end

      def default_author_text
        @meeting.author&.name || User.current.name
      end

      def default_first_page_header_left_text
        @meeting.project&.name || Setting.software_name
      end
    end
  end
end
