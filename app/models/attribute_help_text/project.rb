#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class AttributeHelpText::Project < AttributeHelpText
  def self.available_attributes
    skip = %w[_type links _dependencies id created_at updated_at]

    attributes = API::V3::Projects::Schemas::ProjectSchemaRepresenter
      .representable_definitions
      .reject { |key, _| skip.include?(key.to_s) }
      .transform_values { |definition| definition[:name_source].call }

    ProjectCustomField.find_each do |field|
      attributes[field.attribute_name] = field.name
    end

    attributes['members'] = I18n.t(:label_member_plural)

    attributes
  end

  validates :attribute_name, inclusion: { in: ->(*) { available_attributes.keys } }

  def type_caption
    Project.model_name.human
  end

  def self.visible_condition(_user)
    ::AttributeHelpText.where(attribute_name: available_attributes.keys)
  end
end
