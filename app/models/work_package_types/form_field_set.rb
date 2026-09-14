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

module WorkPackageTypes
  class FormFieldSet
    Field = Data.define(:key, :label, :kind)

    def self.for(variant) = new.for(variant)

    def for(variant)
      variant.attribute_groups.flat_map { group_fields(it) }
    end

    def field_for(key)
      kind = ::CustomField.custom_field_attribute?(key) ? :custom_field : :builtin

      Field.new(key:, label: attribute_labels[key], kind:)
    end

    private

    def group_fields(group)
      if group.is_a?(::Type::QueryGroup)
        [Field.new(key: "table:#{group.translated_key}", label: group.translated_key, kind: :table)]
      else
        group.members.map { field_for(it) }
      end
    end

    def attribute_labels
      @attribute_labels ||= ::TypeVariant.translated_work_package_form_attributes(merge_date: true)
    end
  end
end
