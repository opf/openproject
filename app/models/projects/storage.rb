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

module Projects::Storage
  def self.included(base)
    base.send :extend, StorageMethods
    base.send :include, ModelMethods
  end

  module ModelMethods
    ##
    # Count required disk storage for this project.
    # Returns a hash of the form:
    # 'total' => Total required disk space for this project
    # 'modules' => Hash of localization keys and required space for this module
    def count_required_storage
      storage = self.class.with_required_storage.find(id)

      {
        'total' => storage.required_disk_space,
        'modules' => {
          'label_work_package_plural' => storage.work_package_required_space,
          'project_module_wiki' => storage.wiki_required_space,
          'label_repository' => storage.repositories_required_space
        }.select { |_, v| v.present? && v.positive? }
      }
    end
  end

  module StorageMethods
    ##
    # Count required disk storage used by Projects.
    # This currently provides the following values
    #
    #  - +wiki_required_space+ required disk space from attachments on the wiki
    #  - +work_package_required_space+ required disk space from attachments on work packages
    #  - +repositories_required_space+ required disk space from a locally registered repository
    #  - +required_disk_space+ Total required disk space for this project over these above values.
    def with_required_storage
      Project
        .from("#{Project.table_name} projects")
        .joins("LEFT JOIN (#{wiki_storage_sql}) wiki ON projects.id = wiki.project_id")
        .joins("LEFT JOIN (#{work_package_sql}) wp ON projects.id = wp.project_id")
        .joins("LEFT JOIN #{Repository.table_name} repos ON repos.project_id = projects.id")
        .select('projects.*')
        .select('wiki.filesize AS wiki_required_space')
        .select('wp.filesize AS work_package_required_space')
        .select('repos.required_storage_bytes AS repositories_required_space')
        .select("#{required_disk_space_sum} AS required_disk_space")
    end

    ##
    # Returns the total required disk space for all projects in bytes
    def total_projects_size
      Project
        .from("(#{Project.with_required_storage.to_sql}) sub")
        .sum(:required_disk_space)
    end

    def required_disk_space_sum
      '(COALESCE(wiki.filesize, 0) + COALESCE(wp.filesize, 0) + COALESCE(repos.required_storage_bytes, 0))'
    end

    private

    def wiki_storage_sql
      <<-SQL
      SELECT wiki.project_id, SUM(wiki_attached.filesize) AS filesize
      FROM #{Wiki.table_name} wiki
      JOIN #{WikiPage.table_name} pages
        ON pages.wiki_id = wiki.id
      JOIN #{Attachment.table_name} wiki_attached
        ON (wiki_attached.container_id = pages.id AND wiki_attached.container_type = 'WikiPage')
      GROUP BY wiki.project_id
      SQL
    end

    def work_package_sql
      <<-SQL
      SELECT wp.project_id, SUM(wp_attached.filesize) AS filesize
      FROM #{WorkPackage.table_name} wp
      JOIN #{Attachment.table_name} wp_attached
        ON (wp_attached.container_id = wp.id AND wp_attached.container_type = 'WorkPackage')
      GROUP BY wp.project_id
      SQL
    end
  end
end
