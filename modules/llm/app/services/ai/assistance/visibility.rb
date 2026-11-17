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

module AI
  module Assistance
    # What of a work package's surroundings the user can see: descendants, relations and
    # linked pull requests. Evidence and context never name a work package the user cannot open.
    class Visibility
      MAX_DESCENDANTS = 200

      attr_reader :work_package, :user

      def initialize(work_package:, user:)
        @work_package = work_package
        @user = user
      end

      def descendants
        @descendants ||= work_package.descendants.visible(user).includes(:status, :parent).order(:id).limit(MAX_DESCENDANTS).to_a
      end

      # [relation type seen from this work package, other work package], for every relation
      # to a work package the user can see.
      def relations
        @relations ||= begin
          related = Relation.of_work_package(work_package).includes(from: :status, to: :status).map do |relation|
            [relation.relation_type_for(work_package), relation.other_work_package(work_package)]
          end
          visible_ids = visible_ids_of(related.map { |_type, other| other.id })
          related.select { |_type, other| visible_ids.include?(other.id) }
        end
      end

      # The pull requests of every integration that is enabled in the project and that the
      # user may read.
      def linked_pull_requests
        @linked_pull_requests ||= pull_request_sources.flat_map do |module_name, permission, association, builder|
          next [] unless work_package.project.module_enabled?(module_name)
          next [] unless user.allowed_in_work_package?(permission, work_package)

          work_package.public_send(association).map { |record| LinkedPullRequest.public_send(builder, record) }
        end
      end

      def last_activity_at
        [work_package.journals.maximum(:created_at), work_package.updated_at].compact.max
      end

      private

      def visible_ids_of(ids)
        WorkPackage.visible(user).where(id: ids).pluck(:id)
      end

      def pull_request_sources
        sources = []
        if work_package.respond_to?(:github_pull_requests)
          sources << %i[github show_github_content github_pull_requests from_github]
        end
        if work_package.respond_to?(:gitlab_merge_requests)
          sources << %i[gitlab show_gitlab_content gitlab_merge_requests from_gitlab]
        end
        sources
      end
    end
  end
end
