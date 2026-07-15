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

# Shared behaviour for custom fields that belong to a CustomFieldSection and
# maintain their position within that section via attribute_order.
# Include in UserCustomField and ProjectCustomField.
module CustomField::Sectionable
  extend ActiveSupport::Concern

  included do
    belongs_to :custom_field_section, class_name: "CustomFieldSection",
                                      inverse_of: false

    validates :custom_field_section_id, presence: true

    after_create_commit :add_to_section_order
    after_destroy_commit :remove_from_section_order
  end

  def add_to_section_order
    custom_field_section.add_to_order(column_name)
  end

  def remove_from_section_order
    section = custom_field_section
    section.remove_from_order(column_name) unless section.nil? || section.frozen?
  end
end
