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

module OpenProject
  module StrikezoneFrank
    class Hooks < OpenProject::Hook::ViewListener
      def view_layouts_base_html_head(context)
        context[:hook_caller].render(
          partial: "strikezone_frank/hooks/logo"
        )
      end

      def view_layouts_base_body_bottom(context)
        return unless show_widget?(context)

        context[:hook_caller].render(
          partial: "strikezone_frank/hooks/widget",
          locals: widget_locals(context)
        )
      end

      def application_controller_before_action(context)
        return unless show_widget?(context)

        controller = context[:controller]
        return unless controller.respond_to?(:append_content_security_policy_directives)
        return unless html_request?(controller)

        controller.append_content_security_policy_directives(frame_src: [Embed.origin])
      end

      private

      def show_widget?(context)
        User.current.logged? || !Setting.login_required?
      end

      def widget_locals(context)
        project = context[:project]
        context.merge(
          embed_origin: Embed.origin,
          embed_url: Embed.url(project:),
          host_context: Embed.host_context(project:)
        )
      end

      def html_request?(controller)
        format = controller.request&.format
        format.nil? || format.html?
      end
    end
  end
end
