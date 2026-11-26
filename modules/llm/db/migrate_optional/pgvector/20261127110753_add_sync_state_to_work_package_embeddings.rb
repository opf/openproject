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

class AddSyncStateToWorkPackageEmbeddings < ActiveRecord::Migration[8.1]
  def up
    change_table :work_package_embeddings, bulk: true do |t|
      t.datetime :work_package_updated_at
      t.string :text_digest, limit: 32
      t.datetime :failed_at
    end

    execute "UPDATE work_package_embeddings SET work_package_updated_at = updated_at"

    change_column_null :work_package_embeddings, :work_package_updated_at, false
    change_column_null :work_package_embeddings, :embedding, true
  end

  def down
    execute "DELETE FROM work_package_embeddings WHERE embedding IS NULL"

    change_column_null :work_package_embeddings, :embedding, false
    remove_columns :work_package_embeddings, :work_package_updated_at, :text_digest, :failed_at
  end
end
