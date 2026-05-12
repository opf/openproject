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

class Automations::Actions::CustomField < Automations::Actions::Base
  store_attribute :options, :custom_field_id, :integer

  FORMAT_TO_SUBCLASS = {
    "string" => "Automations::Actions::CustomField::ForString",
    "text" => "Automations::Actions::CustomField::ForText",
    "link" => "Automations::Actions::CustomField::ForLink",
    "int" => "Automations::Actions::CustomField::ForInteger",
    "float" => "Automations::Actions::CustomField::ForFloat",
    "date" => "Automations::Actions::CustomField::ForDate",
    "bool" => "Automations::Actions::CustomField::ForBoolean",
    "user" => "Automations::Actions::CustomField::ForUser",
    "list" => "Automations::Actions::CustomField::ForAssociated",
    "version" => "Automations::Actions::CustomField::ForAssociated"
  }.freeze

  def self.templates
    WorkPackageCustomField.usable_as_automation.filter_map do |cf|
      subclass = subclass_for(cf)
      next unless subclass

      template = subclass.new(custom_field_id: cf.id)
      template.instance_variable_set(:@custom_field, cf)
      template
    end
  end

  def self.subclass_for(custom_field)
    name = FORMAT_TO_SUBCLASS[custom_field.field_format]
    name&.constantize
  end

  def custom_field
    return nil if custom_field_id.blank?

    @custom_field ||= WorkPackageCustomField.find_by(id: custom_field_id)
  end

  def key
    cf = custom_field
    cf ? cf.attribute_name.to_sym : :inexistent_custom_field
  end

  def human_name
    custom_field&.name || super
  end

  private

  def set_custom_field_value(work_package)
    work_package.send(custom_field.attribute_setter, values)
  end

  def validate_custom_field(work_package)
    work_package.custom_values_to_validate += Array(work_package.custom_value_for(custom_field))
  end
end
