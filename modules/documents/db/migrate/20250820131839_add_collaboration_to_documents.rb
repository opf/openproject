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

class AddCollaborationToDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :documents, :kind, :string

    reversible do |dir|
      dir.up do
        set_existing_documents_kind
        change_title_string_size limit: 255
      end
    end

    change_column_default :documents, :kind, from: nil, to: "collaborative"
  end

  private

  def set_existing_documents_kind
    say_with_time "setting existing documents to appropriate kinds" do
      # Set all existing documents to classic kind
      execute <<~SQL.squish
        UPDATE documents
        SET kind = 'classic'
      SQL
    end
  end

  def change_title_string_size(limit:)
    change_column(:documents, :title, :string, limit:)
    change_column(:document_journals, :title, :string, limit:)
  end
end
