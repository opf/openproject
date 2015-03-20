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
      when User, Group
        wp.send(column_name).as_json(only: [:id, :firstname, :type], methods: :name)
      when Version
        wp.send(column_name).as_json(only: [:id, :name])
      when WorkPackage
        wp.send(column_name).as_json(only: [:id, :subject])
      else
        wp.send(column_name)
      end
    end
  end

  node(:custom_values) do |wp|
    wp.custom_values_display_data @custom_field_column_ids
  end

  # add parent id by default to make hierarchies transparent
  node :parent_id do |wp|
    wp.parent_id
  end

  node :updated_at do |wp|
    wp.updated_at.utc.iso8601
  end

  node :created_at do |wp|
    wp.created_at.utc.iso8601
  end

  node :_actions do |wp|
    @can.actions(wp)
  end

  node :_links do |wp|
    if wp.persisted?
      links = {
        edit:       -> { edit_work_package_path(wp) },
        log_time:   -> { new_work_package_time_entry_path(wp) },
        watch:      -> { watcher_link(wp, User.current) },
        duplicate:  -> { new_project_work_package_path({ project_id: wp.project, copy_from: wp }) },
        move:       -> { new_move_work_packages_path(ids: [wp.id]) },
        copy:       -> { new_move_work_packages_path(ids: [wp.id], copy: true) },
        delete:     -> { work_packages_bulk_path(ids: [wp.id], method: :delete) }
      }.select { |action, link| @can.allowed?(wp, action) }

      links = links.update(links) { |key, old_val, new_val| new_val.() }
    end
  end
end

if @display_meta
  node(:meta) { @work_packages_meta_data }
end

node(:_bulk_links) do
  links = {
    edit: edit_work_packages_bulk_path,
    move: new_move_work_packages_path,
    copy: new_move_work_packages_path(copy: true),
    delete: work_packages_bulk_path(_method: :delete)
  }
end

node(:_links) do
  links = {}

  links[:create] = new_project_work_package_path(@project) if User.current.allowed_to?(:add_work_packages, @project)

  links
end
