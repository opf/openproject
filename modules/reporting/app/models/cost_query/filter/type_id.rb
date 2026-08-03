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

class CostQuery::Filter::TypeId < Report::Filter::Base
  join_table WorkPackage => [Entry, :entity]
  applies_for :label_work_package_attributes

  def self.label
    WorkPackage.human_attribute_name(:type)
  end

  # Roots only, read through #name so a variant never shows its own label: users pick the
  # type they see and #transformed_values matches its whole family.
  def self.available_values(*)
    Type.roots.sort_by(&:name).map { |type| [type.name, type.id] }
  end

  # A project runs a single member of a family and its work packages carry that member, so
  # filtering for one type has to match every member.
  def transformed_values
    Type.family_ids(values).presence || values
  end
end
