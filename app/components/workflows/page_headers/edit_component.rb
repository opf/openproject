# frozen_string_literal: true

# -- copyright
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
# ++

module Workflows::PageHeaders
  class EditComponent < BaseComponent
    options :tabs, :roles

    def type = model

    def page_breadcrumb
      { href: workflows_path, text: t(:label_workflow_plural) }
    end

    def title
      type.name
    end

    def add_action_buttons(header)
      header.with_action_button(
        data: { controller: "async-dialog", "admin--workflow-checkbox-state-confirmation-trigger": "click" },
        tag: :a,
        mobile_icon: :copy,
        mobile_label: t(:button_copy),
        size: :medium,
        href: new_workflow_copy_path(type, source_role_id: roles&.first&.id),
        aria: { label: helpers.t(:button_copy) },
        title: helpers.t(:button_copy)
      ) do |button|
        button.with_leading_visual_icon(icon: :copy)
        t(:button_copy)
      end
    end

    def add_tabs(header)
      helpers.render_tab_header_nav(header, tabs)
    end
  end
end
