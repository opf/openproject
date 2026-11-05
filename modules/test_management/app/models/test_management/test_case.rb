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
  class TestCase < ApplicationRecord
    self.table_name = "tm_test_cases"

    STATUSES = %w[ready draft deprecated blocked].freeze
    PRIORITIES = %w[critical high medium low].freeze
    STEP_CONTENT_KEYS = %w[action expected_result data].freeze

    belongs_to :project
    belongs_to :suite, class_name: "TestManagement::Suite", optional: true
    belongs_to :author, class_name: "User", optional: true
    belongs_to :assigned_to, class_name: "User", optional: true
    belongs_to :updated_by, class_name: "User", optional: true

    has_many :steps,
             -> { order(:position) },
             class_name: "TestManagement::TestStep",
             foreign_key: :test_case_id,
             dependent: :destroy,
             inverse_of: :test_case

    has_many :run_cases,
             class_name: "TestManagement::TestRunCase",
             inverse_of: :test_case,
             dependent: :delete_all
    has_many :test_runs, through: :run_cases

    before_validation :normalize_automation_reference
    after_commit :auto_add_to_test_runs, on: %i[create update]

    accepts_nested_attributes_for :steps,
                                  allow_destroy: true,
                                  reject_if: ->(attrs) {
                                    attrs["id"].blank? &&
                                      STEP_CONTENT_KEYS.all? { |key| attrs[key].blank? }
                                  }

    validates :title, presence: true, length: { maximum: 255 }
    validates :status, inclusion: { in: STATUSES }
    validates :priority, inclusion: { in: PRIORITIES }
    validates :automation_reference, length: { maximum: 1024 }
    validate :automation_reference_unique

    scope :visible, ->(user = User.current) {
      includes(:project)
        .references(:projects)
        .merge(Project.allowed_to(user, :view_test_cases))
    }

    scope :in_suite, ->(suite_id) {
      suite_id.present? ? where(suite_id:) : where(suite_id: nil)
    }

    def visible?(user = User.current)
      user&.allowed_in_project?(:view_test_cases, project)
    end

    def formatted_id
      "#{ProjectSetting.display_prefix_for(project)}-#{id}"
    end

    private

    def normalize_automation_reference
      self.automation_reference = automation_reference.to_s.strip.presence
    end

    def automation_reference_unique
      return if automation_reference.blank?

      clash = self.class.where(project_id:, automation_reference:).where.not(id:).exists?
      errors.add(:automation_reference, :taken) if clash
    end

    def auto_add_to_test_runs
      TestManagement::TestRuns::AutoAddService.new(self).call
    end
  end
end
