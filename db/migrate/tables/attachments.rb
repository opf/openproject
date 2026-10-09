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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require_relative "base"

class Tables::Attachments < Tables::Base
  def self.table(migration) # rubocop:disable Metrics/AbcSize
    create_table migration do |t|
      t.bigint :container_id, default: nil, null: true
      t.string :container_type, limit: 30, null: true
      t.string :filename, default: "", null: false
      t.string :disk_filename, default: "", null: false
      t.integer :filesize, default: 0, null: false, limit: 8
      t.string :content_type, default: ""
      t.string :digest, limit: 40, default: "", null: false
      t.integer :downloads, default: 0, null: false
      t.bigint :author_id, null: false
      t.datetime :created_at, precision: nil
      t.string :description
      t.string :file
      t.text :fulltext, limit: 4.megabytes
      t.tsvector :fulltext_tsv
      t.tsvector :file_tsv
      t.datetime :updated_at, precision: nil
      t.integer :status, default: 0, null: false

      t.index :author_id, name: "index_attachments_on_author_id"
      t.index %i[container_id container_type], name: "index_attachments_on_container_id_and_container_type"
      t.index :created_at, name: "index_attachments_on_created_at"
      t.index :fulltext_tsv, using: "gin"
      t.index :file_tsv, using: "gin"
    end
  end
end
