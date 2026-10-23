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

module OpenProject
  module Common
    # @logical_path OpenProject/Common
    class AttributeHelpTextComponentPreview < Lookbook::Preview
      # @param additional_text [String]
      def playground(additional_text: "Show Attribute help text")
        render_with_template(locals: { additional_text:, help_text: project_help_text })
      end

      # @display min_height 400px
      def dialog_component
        render AttributeHelpTexts::ShowDialogComponent.new(
          attribute_help_text: project_help_text,
          current_user: admin_user,
          open: true
        )
      end

      def in_a_form
        render_with_template
      end

      def standalone_caption
        render_with_template(locals: { help_text: project_help_text })
      end

      private

      def admin_user
        FactoryBot.build_stubbed(:admin)
      end

      def project_help_text
        FactoryBot
          .build_stubbed(
            :project_help_text,
            attribute_name: "name",
            caption: "A short summary",
            help_text: <<~MARKDOWN
              #### Goal

              Find something **useful** to say about this project!

              #### Guidance

              The Project name should be concise and describe the project in terms that are understood by all involved.

              _Good examples_

              - 🧹 Spree Cleanup Project
              - 🦦 Thames Sewage Mitigation Project
              - 🏊🏼‍♀️ Public Swimming in the Seine

              _Bad examples_

              - 🔥 Stakeholder-Alignment Mega-Project
              - ✈️ New Airport for Berlin
            MARKDOWN
          )
      end
    end
  end
end
