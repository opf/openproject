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

class AddTsvColumnsToAttachments < ActiveRecord::Migration[5.0]
  def up
    if OpenProject::Database.allows_tsv?
      add_column :attachments, :fulltext_tsv, :tsvector
      add_column :attachments, :file_tsv, :tsvector

      add_index :attachments, :fulltext_tsv, using: "gin"
      add_index :attachments, :file_tsv, using: "gin"
    else
      warn "Your installation does not support full-text search features. Better use PostgreSQL in version 9.5 or higher."
    end
  end

  def down
    if column_exists? :attachments, :fulltext_tsv
      remove_column :attachments, :fulltext_tsv, :tsvector
    end

    if column_exists? :attachments, :file_tsv
      remove_column :attachments, :file_tsv, :tsvector
    end

    if index_exists? :attachments, :fulltext_tsv
      remove_index :attachments, :fulltext_tsv
    end

    if index_exists? :attachments, :file_tsv
      remove_index :attachments, :file_tsv
    end
  end
end
