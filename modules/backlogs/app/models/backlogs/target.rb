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
  # Discriminated union representing a backlog container target.
  # Serialized format: "sprint:{id}", "backlog_bucket:{id}", or "inbox".
  module Target
    # Counterpart of InboxId
    Inbox = Data.define do
      def name = I18n.t(:label_inbox)
    end.new

    SprintId = Data.define(:id) do
      def type = :sprint

      def to_s = "#{type}:#{id}"

      def to_h = { type:, id: }

      def to_filter = { name: "sprint", operator: "!", values: [id] }

      def to_container_params = { sprint_id: id }

      def container_for(project) = Sprint.for_project(project).visible.find_by(id:)
    end

    BucketId = Data.define(:id) do
      def type = :backlog_bucket

      def to_s = "#{type}:#{id}"

      def to_h = { type:, id: }

      def to_filter = { name: "backlogBucket", operator: "!", values: [id] }

      def to_container_params = { backlog_bucket_id: id }

      def container_for(project) = BacklogBucket.for_project(project).visible.find_by(id:)
    end

    InboxId = Data.define do
      def type = :inbox

      delegate :to_s, to: :type

      def to_h = { type: }

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

    def self.parse(value)
      case value.to_s.split(":", 2)
      in ["sprint", /\A\d+\z/ => id]
        SprintId[id.to_i]
      in ["backlog_bucket", /\A\d+\z/ => id]
        BucketId[id.to_i]
      in %w[inbox]
        InboxId
      else
        nil
      end
    end
  end
end
