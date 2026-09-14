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
  # Discriminated union describing where a work package lives (or should move
  # to): a sprint, a backlog bucket, or the inbox. It is the single place that
  # maps between the +(list_type, list_id)+ wire format used by the move and
  # add-existing UIs and the +(sprint_id, backlog_bucket_id)+ columns persisted
  # on the work package.
  module Target
    # Counterpart of InboxId
    Inbox = Data.define do
      def name = I18n.t(:label_inbox)
    end.new

    SprintId = Data.define(:id) do
      def list_type = "sprint"

      def list_id = id

      def to_list_params = { list_type:, list_id: }

      def attributes = { sprint_id: id, backlog_bucket_id: nil }

      def to_filter = { name: "sprint", operator: "!", values: [id] }

      def to_container_params = { sprint_id: id }

      def container_for(project) = Sprint.for_project(project).visible.find_by(id:)
    end

    BucketId = Data.define(:id) do
      def list_type = "backlog_bucket"

      def list_id = id

      def to_list_params = { list_type:, list_id: }

      def attributes = { sprint_id: nil, backlog_bucket_id: id }

      def to_filter = { name: "backlogBucket", operator: "!", values: [id] }

      def to_container_params = { backlog_bucket_id: id }

      def container_for(project) = BacklogBucket.for_project(project).visible.find_by(id:)
    end

    InboxId = Data.define do
      def list_type = "inbox"

      def list_id = nil

      def to_list_params = { list_type: }

      def attributes = { sprint_id: nil, backlog_bucket_id: nil }

      def to_filter = { name: "backlogInbox", operator: "=", values: [OpenProject::Database::DB_VALUE_FALSE] }

      def to_container_params = {}

      def container_for(_project) = Inbox
    end.new

    def self.for(container)
      case container
      in Sprint
        SprintId[container.id]
      in BacklogBucket
        BucketId[container.id]
      in Inbox
        InboxId
      end
    end

    # Encode the current location of a work package.
    def self.for_work_package(work_package)
      if work_package.backlog_bucket_id
        BucketId[work_package.backlog_bucket_id]
      elsif work_package.sprint_id
        SprintId[work_package.sprint_id]
      else
        InboxId
      end
    end

    # Decode a +(list_type, list_id)+ pair from the move UI. Both arguments are
    # normalized to strings, so symbol and integer input decode the same way as
    # the raw params. Returns +nil+ when the combination is invalid (unknown
    # type, missing/non-numeric id for a sprint or bucket, or an id supplied
    # for the inbox).
    def self.from_list(list_type, list_id)
      case [list_type.to_s, list_id.presence&.to_s]
      in ["sprint", /\A\d+\z/ => id]
        SprintId[id.to_i]
      in ["backlog_bucket", /\A\d+\z/ => id]
        BucketId[id.to_i]
      in ["inbox", nil]
        InboxId
      else
        nil
      end
    end
  end
end
