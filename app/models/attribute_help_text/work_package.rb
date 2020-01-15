#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class AttributeHelpText::WorkPackage < AttributeHelpText
  def self.available_attributes
    attributes = ::Type.translated_work_package_form_attributes

    # Start and finish dates are joined into a single field for non-milestones
    attributes.delete 'start_date'
    attributes.delete 'due_date'

    # Status and project are currently special attribute that we need to add
    attributes['status'] = WorkPackage.human_attribute_name 'status'
    attributes['project'] = WorkPackage.human_attribute_name 'project'

    attributes
  end

  validates_inclusion_of :attribute_name, in: ->(*) { available_attributes.keys }

  def attribute_scope
    'WorkPackage'
  end

  def type_caption
    I18n.t(:label_work_package)
  end

  def self.visible_condition(user)
    visible_cf_names = WorkPackageCustomField
                       .visible_by_user(user)
                       .pluck(:id)
                       .map { |id| "custom_field_#{id}" }

    where(attribute_name: visible_cf_names)
      .or(where.not("attribute_name LIKE 'custom_field_%'"))
  end
end
