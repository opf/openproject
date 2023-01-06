#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

module Projects::Copy
  class FileLinksDependentService < ::Copy::Dependency
    def self.human_name
      I18n.t(:'projects.copy.work_package_file_links')
    end

    def source_count
      source.work_packages.joins(:file_links).count('file_links.id')
    end

    protected

    def copy_dependency(*)
      # If no work packages were copied, we cannot copy their attachments
      return unless state.work_package_id_lookup

      state.work_package_id_lookup.each do |old_wp_id, new_wp_id|
        create_work_package_file_links(old_wp_id, new_wp_id)
      end
    end

    def create_work_package_file_links(old_wp_id, new_wp_id)
      Storages::FileLink.where(container_id: old_wp_id).each do |file_link|
        create_file_link(file_link, new_wp_id)
      end
    end

    def create_file_link(file_link, new_wp_id)
      attributes = file_link
        .attributes.dup.except('id', 'container_id', 'created_at', 'updated_at')
        .merge('container_id' => new_wp_id)

      service_result = Storages::FileLinks::CreateService
        .new(user: User.current)
        .call(attributes)

      copied_file_link = service_result.result
      copied_file_link.save
    end
  end
end
