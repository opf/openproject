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
  module TestCases
    class BaseContract < ::ModelContract
      def self.model
        TestManagement::TestCase
      end

      attribute :project
      attribute :suite
      attribute :suite_id
      attribute :title
      attribute :description
      attribute :preconditions
      attribute :priority
      attribute :status
      attribute :automated
      attribute :automation_reference
      attribute :assigned_to
      attribute :assigned_to_id
      attribute :author
      attribute :steps

      validate :user_allowed_to_manage
      validate :suite_in_same_project

      private

      def user_allowed_to_manage
        return if model.project.nil?

        errors.add :base, :error_unauthorized unless permitted?
      end

      def suite_in_same_project
        return if model.suite_id.blank?
        return if model.suite && model.suite.project_id == model.project_id

        errors.add :suite_id, :invalid
      end

      def permitted?
        raise TestManagement::AbstractMethodError
      end
    end
  end
end
