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

module Automations
  class IndexComponent < ::TableComponent
    columns :name, :triggers, :conditions, :actions, :sort

    def headers
      [
        ["name", { caption: Automation.human_attribute_name(:name) }],
        ["triggers", { caption: I18n.t("automations.triggers.name") }],
        ["conditions", { caption: I18n.t("automations.conditions") }],
        ["actions", { caption: I18n.t("automations.actions.name") }],
        ["sort", { caption: I18n.t(:label_sort) }]
      ]
    end

    def sortable?
      false
    end

    def inline_create_link
      link_to new_automation_path,
              aria: { label: t("automations.new") },
              class: "wp-inline-create--add-link",
              title: t("automations.new") do
        helpers.op_icon("icon icon-add")
      end
    end
  end
end
