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

module OpenProject::TextFormatting::Formats
  module Markdown
    class Helper
      attr_reader :view_context

      def initialize(view_context)
        @view_context = view_context
      end

      def wikitoolbar_for(field_id, **context)
        # Hide the original textarea
        view_context.content_for(:additional_js_dom_ready) do
          js = <<-JAVASCRIPT
            var field = document.getElementById('#{field_id}');
            field.style.display = 'none';
            field.removeAttribute('required');
          JAVASCRIPT

          js.html_safe
        end

        # Pass an optional resource to the CKEditor instance
        resource = context.fetch(:resource, {})
        helpers.angular_component_tag "opce-ckeditor-augmented-textarea",
                                      inputs: {
                                        textareaSelector: "##{field_id}",
                                        editorType: context[:editor_type] || "full",
                                        previewContext: context[:preview_context],
                                        resource:,
                                        macros: context.fetch(:macros, true)
                                      }
      end

      protected

      def helpers
        ApplicationController.helpers
      end
    end
  end
end
