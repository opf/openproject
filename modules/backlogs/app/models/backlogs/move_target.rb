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

module Backlogs
  # Value object describing where a story currently lives (or should move to):
  # a sprint, a backlog bucket, or the inbox. It is the single place that maps
  # between the +(list_type, list_id)+ wire format used by the move UI and the
  # +(sprint_id, backlog_bucket_id)+ columns persisted on the work package.
  class MoveTarget
    attr_reader :sprint_id, :backlog_bucket_id

    def initialize(sprint_id: nil, backlog_bucket_id: nil)
      @sprint_id = sprint_id
      @backlog_bucket_id = backlog_bucket_id
    end

    # Encode the current location of a work package.
    def self.for(work_package)
      if work_package.backlog_bucket_id
        new(backlog_bucket_id: work_package.backlog_bucket_id)
      else
        new(sprint_id: work_package.sprint_id)
      end
    end

    # Decode a +(list_type, list_id)+ pair from the move UI. Returns +nil+ when
    # the combination is invalid (unknown type, missing/non-numeric id for a
    # sprint or bucket, or an id supplied for the inbox).
    def self.from_list(list_type, list_id)
      case [list_type, list_id.presence&.to_s]
      in ["sprint", /\A\d+\z/ => sprint_id]
        new(sprint_id:)
      in ["backlog_bucket", /\A\d+\z/ => backlog_bucket_id]
        new(backlog_bucket_id:)
      in ["inbox", nil]
        new
      else
        nil
      end
    end

    def list_type
      if backlog_bucket_id
        "backlog_bucket"
      elsif sprint_id
        "sprint"
      else
        "inbox"
      end
    end

    def list_id
      backlog_bucket_id || sprint_id
    end

    # Attributes to assign to the work package, in the shape the inner
    # WorkPackages::UpdateService expects.
    def attributes
      { backlog_bucket_id:, sprint_id: }
    end
  end
end
