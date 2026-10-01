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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require Rails.root.join("db/migrate/migration_utils/permission_adder")

class UpdateWikiPermissions < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      DELETE FROM role_permissions
      WHERE permission IN ('list_attachments',
                           'manage_wiki_menu',
                           'rename_wiki_pages',
                           'change_wiki_parent_page',
                           'delete_wiki_pages',
                           'export_wiki_pages',
                           'delete_wiki_pages_attachments',
                           'protect_wiki_pages');
    SQL

    ::Migration::MigrationUtils::PermissionAdder.add(:manage_wiki, :edit_wiki_pages)
    ::Migration::MigrationUtils::PermissionAdder.add(:edit_wiki_pages, :view_wiki_pages)
    ::Migration::MigrationUtils::PermissionAdder.add(:view_wiki_edits, :view_wiki_pages)
  end
end
