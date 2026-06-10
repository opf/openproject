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

module OpenProject::Backlogs::Patches::WorkPackagePatch
  extend ActiveSupport::Concern

  included do
    prepend InstanceMethods
    extend ClassMethods

    register_journal_formatted_fields "story_points", "position", formatter_key: :decimal

    validates_numericality_of :story_points, only_integer: true,
                                             allow_nil: true,
                                             greater_than_or_equal_to: 0,
                                             less_than: 10_000,
                                             if: -> { backlogs_enabled? }

    belongs_to :sprint, optional: true
    belongs_to :backlog_bucket, optional: true

    include OpenProject::Backlogs::List

    scopes :in_backlog_for
    scopes :in_inbox_for
    scopes :with_backlogs_neighbours
    scopes :without_status_considered_closed
    scopes :without_excluded_type
  end

  module ClassMethods
    def order_by_position
      order(arel_table[:position].asc.nulls_last)
    end
  end

  module InstanceMethods
    def backlogs_enabled?
      project&.backlogs_enabled?
    end
  end
end
