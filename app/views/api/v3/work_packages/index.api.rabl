#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

object false

child @work_packages => :work_packages do
  @column_names.each do |column_name|
    node(column_name, :if => lambda{ |wp| wp.respond_to?(column_name) }) do |wp|
      case wp.send(column_name)
      when Category
        wp.send(column_name).as_json(only: [:id, :name])
      when Project
        wp.send(column_name).as_json(only: [:id, :name, :identifier])
      when IssuePriority
        wp.send(column_name).as_json(only: [:id, :name])
      when Status
        wp.send(column_name).as_json(only: [:id, :name])
      when User
        wp.send(column_name).as_json(only: [:id, :firstname], methods: :name)
      when Version
        wp.send(column_name).as_json(only: [:id, :name])
      when WorkPackage
        wp.send(column_name).as_json(only: [:id, :name])
      else
        wp.send(column_name)
      end
    end
  end

  node(:custom_values) do |wp|
    wp.custom_values_display_data @custom_field_column_names
  end

  # add parent id by default to make hierarchies transparent
  node :parent_id do |wp|
    wp.parent_id
  end
end

if @display_meta
  node(:meta) { @work_packages_meta_data }
end
