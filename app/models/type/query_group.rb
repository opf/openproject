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

class Type::QueryGroup < Type::FormGroup
  MEMBER_PREFIX = "query_".freeze

  def self.query_attribute?(name)
    name.to_s.match?(/#{Type::QueryGroup::MEMBER_PREFIX}(\d+)/o)
  end

  def self.query_attribute_id(name)
    match = name.to_s.match(/#{Type::QueryGroup::MEMBER_PREFIX}(\d+)/o)

    match ? match[1] : nil
  end

  def query_attribute_name
    :"query_#{query.id}"
  end

  def group_type
    :query
  end

  def ==(other)
    other.is_a?(self.class) &&
      key == other.key &&
      type == other.type &&
      query.to_json == other.attributes.to_json
  end

  alias :query :attributes

  def members
    [attributes]
  end

  def active_members(_project)
    [members]
  end
end
