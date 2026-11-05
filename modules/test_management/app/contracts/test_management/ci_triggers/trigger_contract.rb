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
  module CiTriggers
    class TriggerContract
      include ActiveModel::Validations

      PERMISSION = :trigger_test_automation

      attr_reader :model, :user

      delegate :project, :connection, :run, :suite, :test_case, :mode, to: :model

      validate :user_allowed
      validate :ci_enabled
      validate :connection_usable
      validate :mode_and_scope
      validate :automated_cases_present
      validate :ref_format

      def initialize(model, user)
        @model = model
        @user = user
      end

      delegate :errors, to: :model

      private

      def user_allowed
        return if project && user.allowed_in_project?(PERMISSION, project)

        errors.add(:base, :error_unauthorized)
      end

      def ci_enabled
        return if project.nil? || ::TestManagement::ProjectSetting.enabled?(project, :ci)

        errors.add(:base, :tm_ci_disabled)
      end

      def connection_usable # rubocop:disable Metrics/AbcSize
        if connection.nil? || connection.project_id != project&.id
          errors.add(:connection, :blank)
        elsif !connection.active?
          errors.add(:connection, :inactive)
        elsif (missing = connection.trigger_missing).any?
          errors.add(:connection, :not_ready,
                     missing: missing.map { |a| CiConnection.human_attribute_name(a) }.join(", "))
        end
      end

      def mode_and_scope # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
        errors.add(:mode, :inclusion) unless Request::MODES.include?(mode)
        errors.add(:base, :tm_ci_scope_missing) if [run, suite, test_case].compact.empty?
        errors.add(:base, :tm_ci_scope_ambiguous) if [suite, test_case].compact.size > 1
        errors.add(:suite, :invalid) if suite && suite.project_id != project&.id
        errors.add(:test_case, :invalid) if test_case && (test_case.project_id != project&.id)
        return if run.nil? && !model.new_iteration?

        if run.nil? || run.project_id != project&.id
          errors.add(:run, :blank)
        elsif model.new_iteration? && !run.active?
          errors.add(:run, :tm_run_finished)
        end
      end

      def automated_cases_present
        return if errors.any?
        return if model.automated_cases.exists?

        errors.add(:base, :tm_ci_no_automated_cases)
      end

      def ref_format
        ref = model.ref.to_s.strip
        return if ref.blank?

        errors.add(:ref, :invalid) unless ref.length <= 255 && ref.match?(CiConnection::REF_FORMAT)
      end
    end
  end
end
