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

class Tables::AttachmentJournals < Tables::Base
  def self.table(migration)
    create_table migration do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.bigint :container_id, default: nil, null: true
      t.string :container_type, limit: 30, null: true
      t.string :filename, default: nil, null: false
      t.string :disk_filename, default: nil, null: false
      t.integer :filesize, default: nil, null: false, limit: 8
      t.string :content_type, default: nil
      t.string :digest, limit: 40, default: nil, null: false
      t.integer :downloads, default: nil, null: false
      t.bigint :author_id, null: false
      t.text :description
    end
  end
end
