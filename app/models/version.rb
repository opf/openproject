#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class Version < ActiveRecord::Base
  include Redmine::SafeAttributes
  after_update :update_issues_from_sharing_change
  belongs_to :project
  has_many :fixed_issues, :class_name => 'WorkPackage', :foreign_key => 'fixed_version_id', :dependent => :nullify
  acts_as_customizable
  acts_as_attachable :view_permission => :view_files,
                     :delete_permission => :manage_files

  VERSION_STATUSES = %w(open locked closed)
  VERSION_SHARINGS = %w(none descendants hierarchy tree system)

  attr_protected :project_id

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:project_id]
  validates_length_of :name, :maximum => 60
  validates_format_of :effective_date, :with => /^\d{4}-\d{2}-\d{2}$/, :message => :not_a_date, :allow_nil => true
  validates_format_of :start_date, :with => /^\d{4}-\d{2}-\d{2}$/, :message => :not_a_date, :allow_nil => true
  validates_inclusion_of :status, :in => VERSION_STATUSES
  validates_inclusion_of :sharing, :in => VERSION_SHARINGS
  validate :validate_start_date_before_effective_date

  scope :open, :conditions => {:status => 'open'}
  scope :visible, lambda {|*args| { :include => :project,
                                    :conditions => Project.allowed_to_condition(args.first || User.current, :view_work_packages) } }

  safe_attributes 'name',
    'description',
    'effective_date',
    'due_date',
    'start_date',
    'wiki_page_title',
    'status',
    'sharing',
    'custom_field_values'

  # Returns true if +user+ or current user is allowed to view the version
  def visible?(user=User.current)
    user.allowed_to?(:view_work_packages, self.project)
  end

  # When a version started.
  #
  # Can either be a set date stored in the database or a dynamic one
  # based on the earlist start_date of the fixed_issues
  def start_date
    # when self.id is nil (e.g. when self is a new_record),
    # minimum('start_date') works on all issues with :fixed_version => nil
    # but we expect only issues belonging to this version
    read_attribute(:start_date) || fixed_issues.where(Issue.arel_table[:fixed_version_id].not_eq(nil)).minimum('start_date')
  end

  def due_date
    effective_date
  end

  # Returns the total estimated time for this version
  # (sum of leaves estimated_hours)
  def estimated_hours
    @estimated_hours ||= fixed_issues.leaves.sum(:estimated_hours).to_f
  end

  # Returns the total reported time for this version
  def spent_hours
    @spent_hours ||= TimeEntry.sum(:hours, :include => :work_package, :conditions => ["#{Issue.table_name}.fixed_version_id = ?", id]).to_f
  end

  def closed?
    status == 'closed'
  end

  def open?
    status == 'open'
  end

  # Returns true if the version is completed: due date reached and no open issues
  def completed?
    effective_date && (effective_date <= Date.today) && (open_issues_count == 0)
  end

  def behind_schedule?
    if completed_pourcent == 100
      return false
    elsif due_date && start_date
      done_date = start_date + ((due_date - start_date+1)* completed_pourcent/100).floor
      return done_date <= Date.today
    else
      false # No issues so it's not late
    end
  end

  # Returns the completion percentage of this version based on the amount of open/closed issues
  # and the time spent on the open issues.
  def completed_pourcent
    if issues_count == 0
      0
    elsif open_issues_count == 0
      100
    else
      issues_progress(false) + issues_progress(true)
    end
  end

  # Returns the percentage of issues that have been marked as 'closed'.
  def closed_pourcent
    if issues_count == 0
      0
    else
      issues_progress(false)
    end
  end

  # Returns true if the version is overdue: due date reached and some open issues
  def overdue?
    effective_date && (effective_date < Date.today) && (open_issues_count > 0)
  end

  # Returns assigned issues count
  def issues_count
    @issue_count ||= fixed_issues.count
  end

  # Returns the total amount of open issues for this version.
  def open_issues_count
    @open_issues_count ||= Issue.where(["#{Issue.table_name}.fixed_version_id = ? AND #{IssueStatus.table_name}.is_closed = ?", self.id, false]).includes(:status).size
  end

  # Returns the total amount of closed issues for this version.
  def closed_issues_count
    @closed_issues_count ||= Issue.where(["#{Issue.table_name}.fixed_version_id = ? AND #{IssueStatus.table_name}.is_closed = ?", self.id, true]).includes(:status).size
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

  # Versions are sorted by effective_date and "Project Name - Version name"
  # Those with no effective_date are at the end, sorted by "Project Name - Version name"
  def <=>(version)
    if self.effective_date
      if version.effective_date
        if self.effective_date == version.effective_date
          "#{self.project.name} - #{self.name}" <=> "#{version.project.name} - #{version.name}"
        else
          self.effective_date <=> version.effective_date
        end
      else
        -1
      end
    else
      if version.effective_date
        1
      else
        "#{self.project.name} - #{self.name}" <=> "#{version.project.name} - #{version.name}"
      end
    end
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
    if self.effective_date && self.start_date && self.effective_date < self.start_date
      errors.add :effective_date, :greater_than_start_date
    end
  end

  # Update the issue's fixed versions. Used if a version's sharing changes.
  def update_issues_from_sharing_change
    if sharing_changed?
      if VERSION_SHARINGS.index(sharing_was).nil? ||
          VERSION_SHARINGS.index(sharing).nil? ||
          VERSION_SHARINGS.index(sharing_was) > VERSION_SHARINGS.index(sharing)
        Issue.update_versions_from_sharing_change self
      end
    end
  end

  # Returns the average estimated time of assigned issues
  # or 1 if no issue has an estimated time
  # Used to weigth unestimated issues in progress calculation
  def estimated_average
    if @estimated_average.nil?
      average = fixed_issues.average(:estimated_hours).to_f
      if average == 0
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

        done = fixed_issues.where(["#{IssueStatus.table_name}.is_closed = ?", !open]).
                           includes(:status).
                           sum("COALESCE(#{Issue.table_name}.estimated_hours, #{estimated_average}) * #{ratio}")
        progress = done.to_f / (estimated_average * issues_count)
      end
      progress
    end
  end
end
