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

# The state of one work package at one point in time, as recorded by its journal.
#
# Exists so that WorkPackages::JournalTimeline can return a chainable relation without
# handing out WorkPackage instances: those would carry journalization, semantic identifiers
# and associations resolving against *current* data, none of which is meaningful for a
# historic row. Pointing at the journal table means every journalized attribute is available
# without enumerating it, which keeps the timeline usable for any unit.
#
# Besides the journalized attributes, rows carry +tick+ (the sampled instant),
# +work_package_id+, +journal_id+ and +validity_period+.
class WorkPackages::JournalTimeline::Entry < ApplicationRecord
  self.table_name = "work_package_journals"

  def readonly? = true
end
