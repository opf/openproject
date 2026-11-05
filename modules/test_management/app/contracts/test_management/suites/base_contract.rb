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

module TestManagement
  module Suites
    class BaseContract < ::ModelContract
      def self.model
        TestManagement::Suite
      end

      attribute :project
      attribute :parent
      attribute :parent_id
      attribute :name
      attribute :position

      validate :user_allowed_to_manage
      validate :parent_in_same_project

      private

      def parent_in_same_project
        return if model.parent_id.blank?

        if model.parent.nil? || model.parent.project_id != model.project_id || parent_inside_own_subtree?
          errors.add :parent_id, :invalid
        end
      end

      # Moving a folder below itself or one of its descendants would create a cycle: the
      # subtree disappears from the tree and recursive walks never end.
      def parent_inside_own_subtree?
        return false if model.new_record?

        TestManagement::Suite.subtree_ids(model.project, [model.id]).include?(model.parent_id)
      end

      def user_allowed_to_manage
        return if model.project.nil?

        unless user.allowed_in_project?(:manage_test_suites, model.project)
          errors.add :base, :error_unauthorized
        end
      end
    end
  end
end
