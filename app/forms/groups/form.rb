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
module Groups
  class Form < ApplicationForm
    include CustomFields::CustomFieldRendering

    form do |f|
      f.text_field(
        name: :lastname,
        label: Group.human_attribute_name(:name),
        required: true,
        input_width: :medium,
        autocomplete: "off"
      )

      f.select_list(
        name: :parent_id,
        label: Group.human_attribute_name(:parent),
        include_blank: I18n.t(:label_no_parent_group),
        caption: I18n.t(:label_parent_group_caption),
        input_width: :medium
      ) do |list|
        parent_candidates.each do |group|
          prefix = "\u00A0\u00A0" * (group.hierarchy_depth || 0)
          # Departments managed by LDAP own their sub-tree and cannot be chosen as a manual parent.
          list.option(label: "#{prefix}#{group.name}",
                      value: group.id,
                      selected: model.parent_id == group.id,
                      disabled: group.ldap_managed?)
        end
      end

      render_custom_fields(form: f)

      f.submit(
        name: :submit,
        label: submit_label,
        scheme: :primary
      )
    end

    def initialize(submit_label: I18n.t(:button_save))
      super()
      @submit_label = submit_label
    end

    private

    attr_reader :submit_label

    def custom_fields
      model.available_custom_fields
    end

    def parent_candidates
      @parent_candidates ||= begin
        scope = if model.organizational_unit
                  Group.organizational_units
                else
                  Group.not_organizational_units
                end

        excluded_ids = model.self_and_descendants.pluck(:id).to_set
        scope.in_tree_order.reject { |group| excluded_ids.include?(group.id) }
      end
    end
  end
end
