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

class Version < ApplicationRecord
  include ::Versions::ProjectSharing
  include ::Scopes::Scoped

  belongs_to :project
  has_many :work_packages, dependent: :nullify
  acts_as_customizable

  VERSION_STATUSES = %w(open locked closed).freeze
  VERSION_SHARINGS = %w(none descendants hierarchy tree system).freeze

  validates :name,
            presence: true,
            uniqueness: { scope: [:project_id], case_sensitive: false }

  validates :effective_date, format: { with: /\A\d{4}-\d{2}-\d{2}\z/, message: :not_a_date, allow_nil: true }
  validates :start_date, format: { with: /\A\d{4}-\d{2}-\d{2}\z/, message: :not_a_date, allow_nil: true }
  validates :status, inclusion: { in: VERSION_STATUSES }
  validate :validate_start_date_before_effective_date

  scopes :order_by_semver_name,
         :rolled_up,
         :shared_with

  scope :visible, ->(*args) {
    joins(:project)
      .merge(Project.allowed_to(args.first || User.current, :view_work_packages))
  }

  scope :systemwide, -> { where(sharing: "system") }

  scope :order_by_name, -> { order(Arel.sql("LOWER(#{Version.table_name}.name) ASC")) }

  def self.with_status_open
    where(status: "open")
  end

  # Returns true if +user+ or current user is allowed to view the version
  def visible?(user = User.current)
    user.allowed_in_project?(:view_work_packages, project)
  end

  def due_date
    effective_date
  end

  # Returns the total estimated time for this version
  # (sum of leaves estimated_hours)
  def estimated_hours
    @estimated_hours ||= work_packages.leaves.sum(:estimated_hours).to_f
  end

  # Returns the total reported time for this version
  def spent_hours
    @spent_hours ||= TimeEntry
      .not_ongoing
      .includes(:work_package)
      .where(work_packages: { version_id: id })
      .sum(:hours)
      .to_f
  end

  def closed?
    status == "closed"
  end

  def open?
    status == "open"
  end

  # Returns true if the version is completed: finish date reached and no open issues
  def completed?
    effective_date && (effective_date <= Date.today) && open_issues_count.zero?
  end

  def systemwide?
    sharing == "system"
  end

  # Returns the completion percentage of this version based on the amount of open/closed issues
  # and the time spent on the open issues.
  def completed_percent
    if issues_count.zero?
      0
    elsif open_issues_count.zero?
      100
    else
      issues_progress(false) + issues_progress(true)
    end
  end

  # Returns the percentage of issues that have been marked as 'closed'.
  def closed_percent
    if issues_count.zero?
      0
    else
      issues_progress(false)
    end
  end

  # Returns true if the version is overdue: finish date reached and some open issues
  def overdue?
    effective_date && (effective_date < Date.today) && (open_issues_count > 0)
  end

  # Returns assigned issues count
  def issues_count
    @issue_count ||= work_packages.count
  end

  # Returns the total amount of open issues for this version.
  def open_issues_count
    @open_issues_count ||= work_packages.merge(WorkPackage.with_status_open).size
  end

  # Returns the total amount of closed issues for this version.
  def closed_issues_count
    @closed_issues_count ||= work_packages.merge(WorkPackage.with_status_closed).size
  end

  def wiki_page
    if project.wiki && wiki_page_title.present?
      @wiki_page ||= project.wiki.find_page(wiki_page_title)
    end
    @wiki_page
  end

  def to_s
    name
  end

  def to_s_with_project
    "#{project} - #{name}"
  end

  def to_s_for_project(other_project)
    if other_project == project
      name
    else
      to_s_with_project
    end
  end

  # Versions are sorted by "Project Name - Version name"
  def <=>(other)
    # using string interpolation for comparison is not efficient
    # (see to_s_with_project's implementation) but I wanted to
    # tie the comparison to the presentation as sorting is mostly
    # used within sorted tables.
    # Thus, when the representation changes, the sorting will change as well.
    to_s_with_project.downcase <=> other.to_s_with_project.downcase
  end

  private

  def validate_start_date_before_effective_date
    if effective_date && start_date && effective_date < start_date
      errors.add :effective_date, :greater_than_start_date
    end
  end

  # Returns the average estimated time of assigned issues
  # or 1 if no issue has an estimated time
  # Used to weight unestimated issues in progress calculation
  def estimated_average
    if @estimated_average.nil?
      average = work_packages.average(:estimated_hours).to_f
      if average.zero?
        average = 1
      end
      @estimated_average = average
    end
    @estimated_average
  end

  # Returns the total progress of open or closed issues.  The returned percentage takes into account
  # the amount of estimated time set for this version.
  #
  # Examples:
  # issues_progress(true)   => returns the progress percentage for open issues.
  # issues_progress(false)  => returns the progress percentage for closed issues.
  def issues_progress(open)
    @issues_progress ||= {}
    @issues_progress[open] ||= begin
      progress = 0

      if issues_count > 0
        ratio = open ? "done_ratio" : 100
        sum_sql = self.class.sanitize_sql_array(
          ["COALESCE(#{WorkPackage.table_name}.estimated_hours, ?) * #{ratio}", estimated_average]
        )

        done = work_packages
          .where(statuses: { is_closed: !open })
          .includes(:status)
          .sum(sum_sql)
        progress = done.to_f / (estimated_average * issues_count)
      end
      progress
    end
  end
end
