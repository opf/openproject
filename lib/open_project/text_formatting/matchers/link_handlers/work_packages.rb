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

module OpenProject::TextFormatting::Matchers
  module LinkHandlers
    class WorkPackages < Base
      ##
      # Match work package links.
      # Condition: Separator is #|##|###
      # Condition: Prefix is nil
      def applicable?
        %w(# ## ###).include?(matcher.sep) && matcher.prefix.nil?
      end

      #
      # Examples:
      #
      # #1234, ##1234, ###1234
      def call
        wp_id = matcher.identifier.to_i

        # Ensure that the element was entered numeric,
        # prohibits links to things like #0123
        return if wp_id.to_s != matcher.identifier

        if matcher.sep == "##" || matcher.sep == "###"
          render_work_package_macro(wp_id, detailed: (matcher.sep === "###"))
        else
          render_work_package_link(wp_id)
        end
      end

      private

      def render_work_package_macro(wp_id, detailed: false)
        ApplicationController.helpers.content_tag "opce-macro-wp-quickinfo",
                                                  "",
                                                  data: { id: wp_id, detailed: }
      end

      def render_work_package_link(wp_id)
        link_to("##{wp_id}",
                work_package_path_or_url(id: wp_id, only_path: context[:only_path]),
                class: "issue work_package preview-trigger")
      end
    end
  end
end
