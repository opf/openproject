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

class Type::AttributeGroup < Type::FormGroup
  def members
    # The attributes might not be present anymore, for instance when you remove
    # a plugin leaving an empty group behind. If we did not delete such a
    # group, the admin saving such a form configuration would encounter an
    # unexpected/unexplicable validation error.
    valid_keys = type.work_package_attributes.keys

    (attributes & valid_keys)
  end

  def group_type
    :attribute
  end

  def ==(other)
    other.is_a?(self.class) &&
      key == other.key &&
      type == other.type &&
      attributes == other.attributes
  end

  def active_members(project)
    members.select do |prop|
      type.passes_attribute_constraint?(prop, project:)
    end
  end
end
