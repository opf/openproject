# frozen_string_literal: true

# -- copyright
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
# ++

require Rails.root.join("db/migrate/tables/base").to_s

class Tables::Documents < Tables::Base
  def self.table(migration)
    create_table migration do |t|
      t.bigint :project_id, null: false, index: { name: "documents_project_id" }
      t.bigint :category_id, null: false, index: { name: "index_documents_on_category_id" }
      t.string :title, limit: 60, default: "", null: false
      t.text :description
      t.datetime :created_at, precision: nil, index: { name: "index_documents_on_created_at" }
      t.datetime :updated_at, precision: nil
      t.text :content_binary
    end
  end
end
