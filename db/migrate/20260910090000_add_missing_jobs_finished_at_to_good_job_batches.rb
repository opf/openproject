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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# 20250210184018_add_jobs_finished_at_to_good_job_batches was emptied out when the
# column moved into Tables::GoodJobBatches, although it had never shipped in an
# OpenProject 16 release. Installations upgrading from 16 therefore never received
# the column, while fresh installations get it from the table class.
class AddMissingJobsFinishedAtToGoodJobBatches < ActiveRecord::Migration[8.1]
  def up
    add_column :good_job_batches, :jobs_finished_at, :datetime, if_not_exists: true
  end

  def down
    # No-op. The column belongs to the table as described in
    # Tables::GoodJobBatches, so it must not be removed here.
  end
end
