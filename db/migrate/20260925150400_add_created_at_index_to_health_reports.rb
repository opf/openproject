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

# health_reports is shared with the storages and wikis modules, and every one
# of them reads the newest report for a subject, so the read needs created_at
# in the index to avoid a sort. The [subject_type, subject_id] prefix serves
# every lookup the polymorphic index did.
class AddCreatedAtIndexToHealthReports < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :health_reports,
              %i[subject_type subject_id created_at],
              algorithm: :concurrently,
              if_not_exists: true

    remove_index :health_reports,
                 %i[subject_type subject_id],
                 name: "index_health_reports_on_subject",
                 algorithm: :concurrently,
                 if_exists: true
  end
end
