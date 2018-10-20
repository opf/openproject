#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class Version < ActiveRecord::Base
  extend DeprecatedAlias

  include Version::ProjectSharing

  after_update :update_issues_from_sharing_change, if: :saved_change_to_sharing?
  belongs_to :project
  has_many :fixed_issues, class_name: 'WorkPackage', foreign_key: 'fixed_version_id', dependent: :nullify
  has_many :work_packages, foreign_key: :fixed_version_id
  acts_as_customizable

  VERSION_STATUSES = %w(open locked closed).freeze
  VERSION_SHARINGS = %w(none descendants hierarchy tree system).freeze

  validates_presence_of :name
  validates_uniqueness_of :name, scope: [:project_id]
  validates_length_of :name, maximum: 60
  validates_format_of :effective_date, with: /\A\d{4}-\d{2}-\d{2}\z/, message: :not_a_date, allow_nil: true
  validates_format_of :start_date, with: /\A\d{4}-\d{2}-\d{2}\z/, message: :not_a_date, allow_nil: true
  validates_inclusion_of :status, in: VERSION_STATUSES
  validates_inclusion_of :sharing, in: VERSION_SHARINGS
  validate :validate_start_date_before_effective_date

  scope :visible, ->(*args) {
    joins(:project)
      .merge(Project.allowed_to(args.first || User.current, :view_work_packages))
  }

  scope :systemwide, -> { where(sharing: 'system') }

  scope :order_by_name, -> { order("LOWER(#{Version.table_name}.name)") }

  def self.with_status_open
    where(status: 'open')
  end

  # Returns true if +user+ or current user is allowed to view the version
  def visible?(user = User.current)
    user.allowed_to?(:view_work_packages, project)
  end

  # When a version started.
  #
  # Can either be a set date stored in the database or a dynamic one
  # based on the earlist start_date of the fixed_issues
  def start_date
    # when self.id is nil (e.g. when self is a new_record),
    # minimum('start_date') works on all issues with fixed_version: nil
    # but we expect only issues belonging to this version
    read_attribute(:start_date) || fixed_issues.where(WorkPackage.arel_table[:fixed_version_id].not_eq(nil)).minimum('start_date')
  end

  def due_date
    effective_date
  end

  # Returns the total estimated time for this version
  # (sum of leaves estimated_hours)
  def estimated_hours
    @estimated_hours ||= fixed_issues.hierarchy_leaves.sum(:estimated_hours).to_f
  end

  # Returns the total reported time for this version
  def spent_hours
    @spent_hours ||= TimeEntry
                     .includes(:work_package)
                     .where(work_packages: { fixed_version_id: id })
                     .sum(:hours)
                     .to_f
  end

  def closed?
    status == 'closed'
  end

  def open?
    status == 'open'
  end

  # Returns true if the version is completed: finish date reached and no open issues
  def completed?
    effective_date && (effective_date <= Date.today) && open_issues_count.zero?
  end

  def behind_schedule?
    if completed_percent == 100
      false
    elsif due_date && start_date
      done_date = start_date + ((due_date - start_date + 1) * completed_percent / 100).floor
      done_date <= Date.today
    else
      false # No issues so it's not late
    end
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
  deprecated_alias :completed_pourcent, :completed_percent

  # Returns the percentage of issues that have been marked as 'closed'.
  def closed_percent
    if issues_count.zero?
      0
    else
      issues_progress(false)
    end
  end
  deprecated_alias :closed_pourcent, :closed_percent

  # Returns true if the version is overdue: finish date reached and some open issues
  def overdue?
    effective_date && (effective_date < Date.today) && (open_issues_count > 0)
  end

  # Returns assigned issues count
  def issues_count
    @issue_count ||= fixed_issues.count
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
    if project.wiki && !wiki_page_title.blank?
      @wiki_page ||= project.wiki.find_page(wiki_page_title)
    end
    @wiki_page
  end

  def to_s; name end

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

  # Returns the sharings that +user+ can set the version to
  def allowed_sharings(user = User.current)
    VERSION_SHARINGS.select do |s|
      if sharing == s
        true
      else
        case s
        when 'system'
          # Only admin users can set a systemwide sharing
          user.admin?
        when 'hierarchy', 'tree'
          # Only users allowed to manage versions of the root project can
          # set sharing to hierarchy or tree
          project.nil? || user.allowed_to?(:manage_versions, project.root)
        else
          true
        end
      end
    end
  end

  private

  def validate_start_date_before_effective_date
    if effective_date && start_date && effective_date < start_date
      errors.add :effective_date, :greater_than_start_date
    end
  end

  # Update the issue's fixed versions. Used if a version's sharing changes.
  def update_issues_from_sharing_change
    if VERSION_SHARINGS.index(sharing_before_last_save).nil? ||
       VERSION_SHARINGS.index(sharing).nil? ||
       VERSION_SHARINGS.index(sharing_before_last_save) > VERSION_SHARINGS.index(sharing)
      WorkPackage.update_versions_from_sharing_change self
    end
  end

  # Returns the average estimated time of assigned issues
  # or 1 if no issue has an estimated time
  # Used to weight unestimated issues in progress calculation
  def estimated_average
    if @estimated_average.nil?
      average = fixed_issues.average(:estimated_hours).to_f
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
        ratio = open ? 'done_ratio' : 100

        done = fixed_issues
               .where(statuses: { is_closed: !open })
               .includes(:status)
               .sum("COALESCE(#{WorkPackage.table_name}.estimated_hours, #{estimated_average}) * #{ratio}")
        progress = done.to_f / (estimated_average * issues_count)
      end
      progress
    end
  end
end
