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

class WorkPackage < ApplicationRecord
  include WorkPackage::Validations
  include WorkPackage::SchedulingRules
  include WorkPackage::StatusTransitions
  include WorkPackage::AskBeforeDestruction
  include WorkPackage::TimeEntriesCleaner
  include WorkPackage::Ancestors
  include WorkPackage::CustomActioned
  include WorkPackage::Hooks
  include WorkPackages::DerivedDates
  include WorkPackages::SpentTime
  include WorkPackages::Costs
  include WorkPackages::Relations
  include ::Scopes::Scoped
  include HasMembers

  include OpenProject::Journal::AttachmentHelper

  DONE_RATIO_OPTIONS = %w[field status].freeze
  TOTAL_PERCENT_COMPLETE_MODE_OPTIONS = %w[work_weighted_average simple_average].freeze

  belongs_to :project
  belongs_to :type
  belongs_to :status, class_name: "Status"
  belongs_to :author, class_name: "User"
  belongs_to :assigned_to, class_name: "Principal", optional: true
  belongs_to :responsible, class_name: "Principal", optional: true
  belongs_to :version, optional: true
  belongs_to :priority, class_name: "IssuePriority"
  belongs_to :category, class_name: "Category", optional: true

  has_many :time_entries, dependent: :delete_all

  has_many :file_links, dependent: :delete_all, class_name: "Storages::FileLink", as: :container

  has_many :storages, through: :project

  has_and_belongs_to_many :changesets, -> { # rubocop:disable Rails/HasAndBelongsToMany
    order("#{Changeset.table_name}.committed_on ASC, #{Changeset.table_name}.id ASC")
  }

  has_and_belongs_to_many :github_pull_requests # rubocop:disable Rails/HasAndBelongsToMany

  has_many :meeting_agenda_items, dependent: :nullify
  # The MeetingAgendaItem has a default order, but the ordered field is not part of the select
  # that retrieves the meetings, hence we need to remove the order.
  has_many :meetings, -> { unscope(:order).distinct }, through: :meeting_agenda_items, source: :meeting

  scope :recently_updated, -> {
    order(updated_at: :desc)
  }

  scope :visible, ->(user = User.current) { allowed_to(user, :view_work_packages) }

  scope :in_status, ->(*args) do
    where(status_id: (args.first.respond_to?(:id) ? args.first.id : args.first))
  end

  scope :for_projects, ->(projects) {
    where(project_id: projects)
  }

  scope :changed_since, ->(changed_since) {
    if changed_since
      where(["#{WorkPackage.table_name}.updated_at >= ?", changed_since])
    end
  }

  scope :with_status_open, -> {
    includes(:status)
      .where(statuses: { is_closed: false })
  }

  scope :with_status_closed, -> {
    includes(:status)
      .where(statuses: { is_closed: true })
  }

  scope :with_limit, ->(limit) {
    limit(limit)
  }

  scope :on_active_project, -> {
    includes(:status, :project, :type)
      .where(projects: { active: true })
  }

  scope :without_version, -> {
    where(version_id: nil)
  }

  scope :with_query, ->(query) {
    where(query.statement)
  }

  scope :with_author, ->(author) {
    where(author_id: author.id)
  }

  scopes :covering_dates_and_days_of_week,
         :allowed_to,
         :for_scheduling,
         :include_derived_dates,
         :include_spent_time,
         :involving_user,
         :left_join_self_and_descendants,
         :relatable,
         :directly_related

  acts_as_watchable(permission: :view_work_packages)

  after_validation :set_attachments_error_details,
                   if: lambda { |work_package| work_package.errors.messages.has_key? :attachments }
  before_save :close_duplicates, :update_done_ratio_from_status
  before_create :default_assign
  # By using prepend: true, the callback will be performed before the meeting_agenda_items are nullified,
  # thus the associated agenda items will be available at the time the callback method is performed.
  around_destroy :save_agenda_item_journals, prepend: true, if: -> { meeting_agenda_items.any? }

  acts_as_customizable

  acts_as_searchable columns: ["subject",
                               "#{table_name}.description",
                               {
                                 name: "#{Journal.table_name}.notes",
                                 scope: -> { Journal.for_work_package.where("journable_id = #{table_name}.id") }
                               }],
                     tsv_columns: [
                       {
                         table_name: Attachment.table_name,
                         column_name: "fulltext",
                         normalization_type: :text,
                         scope: -> { Attachment.where(container_type: name).where("container_id = #{table_name}.id") }
                       },
                       {
                         table_name: Attachment.table_name,
                         column_name: "file",
                         normalization_type: :filename,
                         scope: -> { Attachment.where(container_type: name).where("container_id = #{table_name}.id") }
                       }
                     ],
                     include: %i(project journals),
                     references: %i(projects),
                     date_column: "#{quoted_table_name}.created_at",
                     # sort by id so that limited eager loading doesn't break with postgresql
                     order_column: "#{table_name}.id"

  # makes virtual modal WorkPackageHierarchy available
  has_closure_tree

  # Add on_destroy paper trail
  has_paper_trail

  ##################### WARNING #####################
  # Do not change the order of acts_as_attachable   #
  # and acts_as_journalized!                        #
  #                                                 #
  # This order ensures that no journal entries are  #
  # written after a project is destroyed.           #
  #                                                 #
  # See test/unit/project_test.rb                   #
  # test_destroying_root_projects_should_clear_data #
  # for details.                                    #
  ###################################################
  acts_as_attachable order: "#{Attachment.table_name}.file",
                     add_on_new_permission: :add_work_packages,
                     add_on_persisted_permission: %i[edit_work_packages add_work_package_attachments],
                     modification_blocked: ->(*) { readonly_status? },
                     extract_tsv: true

  associated_to_ask_before_destruction TimeEntry,
                                       ->(work_packages) {
                                         TimeEntry.on_work_packages(work_packages).count > 0
                                       },
                                       method(:cleanup_time_entries_before_destruction_of)

  include WorkPackage::Journalized
  prepend Journable::Timestamps

  def self.status_based_mode?
    Setting.work_package_done_ratio == "status"
  end

  def self.work_based_mode?
    Setting.work_package_done_ratio == "field"
  end

  def self.complete_on_status_closed?
    Setting.percent_complete_on_status_closed == "set_100p"
  end

  # Returns true if usr or current user is allowed to view the work_package
  def visible?(usr = User.current)
    usr.allowed_in_work_package?(:view_work_packages, self)
  end

  # RELATIONS
  def blockers
    # return work_packages that block me
    return WorkPackage.none if closed?

    blocking_relations = Relation.blocks.where(to_id: self)

    WorkPackage
      .where(id: blocking_relations.select(:from_id))
      .with_status_open
  end

  # Returns true if this work package is blocked by another work package that is still open
  def blocked?
    blockers
      .exists?
  end

  def visible_relations(user)
    relations
      .visible(user)
  end

  def add_time_entry(attributes = {})
    attributes.reverse_merge!(
      project:,
      work_package: self
    )
    time_entries.build(attributes)
  end

  # Versions that the work_package can be assigned to
  # A work_package can be assigned to:
  #   * any open, shared version of the project the wp belongs to
  #   * the version it was already assigned to
  #     (to make sure, that you can still update closed tickets)
  #   * for custom fields only_open: false can be used, if the CF is configured so
  def assignable_versions(only_open: true)
    if only_open
      @assignable_versions ||= begin
        current_version = version_id_changed? ? Version.find_by(id: version_id_was) : version
        ((project&.assignable_versions || []) + [current_version]).compact.uniq
      end
    else
      # The called method memoizes the result, no need to memoize it here.
      project&.assignable_versions(only_open: false)
    end
  end

  def to_s
    "#{type.is_standard ? '' : type.name} ##{id}: #{subject}"
  end

  # Return true if the work_package is closed, otherwise false
  def closed?
    status.nil? || status.is_closed?
  end

  # Return true if the work_package's status is_readonly
  # Careful not to use +readonly?+ which is AR internals!
  def readonly_status?
    status.present? && status.is_readonly?
  end

  # Returns true if the work_package is overdue
  def overdue?
    !due_date.nil? && (due_date < Time.zone.today) && !closed?
  end

  def milestone?
    type&.is_milestone?
  end

  alias_method :is_milestone?, :milestone?

  def included_in_totals_calculation?
    !status.excluded_from_totals
  end

  def done_ratio
    if WorkPackage.status_based_mode? && status && status.default_done_ratio
      status.default_done_ratio
    else
      read_attribute(:done_ratio)
    end
  end

  def hide_attachments?
    if project&.deactivate_work_package_attachments.nil?
      !Setting.show_work_package_attachments
    else
      project&.deactivate_work_package_attachments?
    end
  end

  def estimated_hours=(hours)
    write_attribute :estimated_hours, convert_duration_to_hours(hours)
  end

  def remaining_hours=(hours)
    write_attribute :remaining_hours, convert_duration_to_hours(hours)
  end

  def done_ratio=(value)
    write_attribute :done_ratio, convert_value_to_percentage(value)
  end

  def set_derived_progress_hint(field_name, hint, **params)
    derived_progress_hints[field_name] = ProgressHint.new("#{field_name}.#{hint}", params)
  end

  def derived_progress_hint(field_name)
    derived_progress_hints[field_name]
  end

  def duration_in_hours
    duration ? duration * 24 : nil
  end

  # aliasing subject to name
  # using :alias is not possible as AR will add the subject method later
  def name
    subject
  end

  def status_id=(sid)
    self.status = nil
    write_attribute(:status_id, sid)
  end

  def priority_id=(pid)
    self.priority = nil
    write_attribute(:priority_id, pid)
  end

  def type_id=(tid)
    self.type = nil
    write_attribute(:type_id, tid)
  end

  # Overrides attributes= so that type_id gets assigned first
  def attributes=(new_attributes)
    return if new_attributes.nil?

    new_type_id = new_attributes["type_id"] || new_attributes[:type_id]
    if new_type_id
      self.type_id = new_type_id
    end

    super
  end

  # Set the done_ratio using the status if that setting is set.  This will keep the done_ratios
  # even if the user turns off the setting later
  def update_done_ratio_from_status
    if WorkPackage.status_based_mode? && status && status.default_done_ratio
      self.done_ratio = status.default_done_ratio
    end
  end

  # check if user is allowed to edit WorkPackage Journals.
  # see Acts::Journalized::Permissions#journal_editable_by
  def journal_editable_by?(journal, user)
    user.allowed_in_project?(:edit_work_package_notes, project) ||
      (user.allowed_in_work_package?(:edit_own_work_package_notes, self) && journal.user_id == user.id)
  end

  # Returns a scope for the projects
  # the user is allowed to move a work package to
  def self.allowed_target_projects_on_move(user)
    Project.allowed_to(user, :move_work_packages)
  end

  # Returns a scope for the projects
  # the user is create a work package in
  def self.allowed_target_projects_on_create(user)
    Project.allowed_to(user, :add_work_packages)
  end

  # Unassigns issues from +version+ if it's no longer shared with issue's project
  def self.update_versions_from_sharing_change(version)
    # Update issues assigned to the version
    update_versions(["#{WorkPackage.table_name}.version_id = ?", version.id])
  end

  # Unassigns issues from versions that are no longer shared
  # after +project+ was moved
  def self.update_versions_from_hierarchy_change(project)
    moved_project_ids = project.self_and_descendants.reload.map(&:id)
    # Update issues of the moved projects and issues assigned to a version of a moved project
    update_versions(
      ["#{Version.table_name}.project_id IN (?) OR #{WorkPackage.table_name}.project_id IN (?)",
       moved_project_ids,
       moved_project_ids]
    )
  end

  # Extracted from the ReportsController.
  def self.by_type(project)
    count_and_group_by project:,
                       field: "type_id",
                       joins: ::Type.table_name
  end

  def self.by_version(project)
    count_and_group_by project:,
                       field: "version_id",
                       joins: Version.table_name
  end

  def self.by_priority(project)
    count_and_group_by project:,
                       field: "priority_id",
                       joins: IssuePriority.table_name
  end

  def self.by_category(project)
    count_and_group_by project:,
                       field: "category_id",
                       joins: Category.table_name
  end

  def self.by_assigned_to(project)
    count_and_group_by project:,
                       field: "assigned_to_id",
                       joins: User.table_name
  end

  def self.by_responsible(project)
    count_and_group_by project:,
                       field: "responsible_id",
                       joins: User.table_name
  end

  def self.by_author(project)
    count_and_group_by project:,
                       field: "author_id",
                       joins: User.table_name
  end

  def self.by_subproject(project)
    return unless project.descendants.active.any?

    ActiveRecord::Base.connection.select_all(
      "select    s.id as status_id,
        s.is_closed as closed,
        i.project_id as project_id,
        count(i.id) as total
      from
        #{WorkPackage.table_name} i, #{Status.table_name} s
      where
        i.status_id=s.id
        and i.project_id IN (#{project.descendants.active.map(&:id).join(',')})
      group by s.id, s.is_closed, i.project_id"
    ).to_a
  end

  def self.order_by_ancestors(direction)
    max_relation_depth = WorkPackageHierarchy
                         .group(:descendant_id)
                         .select(:descendant_id,
                                 "MAX(generations) AS depth")

    joins("LEFT OUTER JOIN (#{max_relation_depth.to_sql}) AS max_depth ON max_depth.descendant_id = work_packages.id")
      .reorder(Arel.sql("COALESCE(max_depth.depth, 0) #{direction}"))
      .select("#{table_name}.*, COALESCE(max_depth.depth, 0)")
  end

  # Overrides Redmine::Acts::Customizable::ClassMethods#available_custom_fields
  def self.available_custom_fields(work_package)
    if work_package.project_id && work_package.type_id
      RequestStore.fetch(available_custom_field_key(work_package)) do
        available_custom_fields_from_db([work_package])
      end
    else
      []
    end
  end

  def self.preload_available_custom_fields(work_packages)
    custom_fields = available_custom_fields_from_db(work_packages)
                    .select("array_agg(projects.id) available_project_ids",
                            "array_agg(types.id) available_type_ids",
                            "custom_fields.*")
                    .group("custom_fields.id")

    work_packages.each do |work_package|
      RequestStore.store[available_custom_field_key(work_package)] = custom_fields
                                                                       .select do |cf|
        (cf.available_project_ids.include?(work_package.project_id) || cf.is_for_all?) &&
        cf.available_type_ids.include?(work_package.type_id)
      end
    end
  end

  def self.available_custom_fields_from_db(work_packages)
    WorkPackageCustomField
      .left_joins(:projects, :types)
      .where(projects: { id: work_packages.map(&:project_id).uniq },
             types: { id: work_packages.map(&:type_id).uniq })
      .or(WorkPackageCustomField
            .left_joins(:projects, :types)
            .references(:projects, :types)
            .where(is_for_all: true)
            .where(types: { id: work_packages.map(&:type_id).uniq }))
      .distinct
  end

  private_class_method :available_custom_fields_from_db

  def self.available_custom_field_key(work_package)
    :"#work_package_custom_fields_#{work_package.project_id}_#{work_package.type_id}"
  end

  private_class_method :available_custom_field_key

  def custom_field_cache_key
    [project_id, type_id]
  end

  protected

  def <=>(other)
    other.id <=> id
  end

  private

  def derived_progress_hints
    @derived_progress_hints ||= {}
  end

  def add_time_entry_for(user, attributes)
    return if time_entry_blank?(attributes)

    attributes.reverse_merge!(user:,
                              spent_on: Time.zone.today)

    time_entries.build(attributes)
  end

  def convert_duration_to_hours(value)
    if value.is_a?(String)
      begin
        value = DurationConverter.parse(value)
      rescue ChronicDuration::DurationParseError
        # keep invalid value, error shall be caught by numericality validator
      end
    end
    value
  end

  def convert_value_to_percentage(value)
    if value.is_a?(String) && PercentageConverter.valid?(value)
      value = PercentageConverter.parse(value)
    end
    value
  end

  ##
  # Checks if the time entry defined by the given attributes is blank.
  # A time entry counts as blank despite a selected activity if that activity
  # is simply the default activity and all other attributes are blank.
  def time_entry_blank?(attributes)
    return true if attributes.nil?

    key = "activity_id"
    id = attributes[key]
    default_id = if id.present?
                   Enumeration.exists? id:, is_default: true, type: "TimeEntryActivity"
                 else
                   true
                 end

    default_id && attributes.except(key).values.all?(&:blank?)
  end

  def self.having_version_from_other_project
    where(
      "#{WorkPackage.table_name}.version_id IS NOT NULL" +
      " AND #{WorkPackage.table_name}.project_id <> #{Version.table_name}.project_id" +
      " AND #{Version.table_name}.sharing <> 'system'"
    )
  end

  private_class_method :having_version_from_other_project

  # Update issues so their versions are not pointing to a
  # version that is not shared with the issue's project
  def self.update_versions(conditions = nil)
    # Only need to update issues with a version from
    # a different project and that is not systemwide shared
    having_version_from_other_project
      .where(conditions)
      .includes(:project, :version)
      .references(:versions).find_each do |issue|
      next if issue.project.nil? || issue.version.nil?

      unless issue.project.shared_versions.include?(issue.version)
        issue.version = nil
        issue.save
      end
    end
  end

  private_class_method :update_versions

  # Default assignment based on category
  def default_assign
    if assigned_to.nil? && category && category.assigned_to
      self.assigned_to = category.assigned_to
    end
  end

  # Closes duplicates if the work_package is being closed
  def close_duplicates
    return unless closing?

    duplicated_relations.includes(:from).map(&:from).each do |duplicate|
      # Reload is needed in case the duplicate was updated by a previous duplicate
      duplicate.reload
      # Don't re-close it if it's already closed
      next if duplicate.closed?

      # Close the duplicate
      close_duplicate(duplicate)
    end
  end

  def close_duplicate(duplicate)
    WorkPackages::UpdateService
      .new(user: User.system, model: duplicate, contract_class: EmptyContract)
      .call(status:, journal_cause: Journal::CausedByDuplicateWorkPackageClose.new(work_package: self))
      .on_failure { |res| Rails.logger.error "Failed to close duplicate ##{duplicate.id} of ##{id}: #{res.message}" }
  end

  # Query generator for selecting groups of issue counts for a project
  # based on specific criteria.
  # DANGER: :field and :joins MUST never come from user input, because
  # they are not SQL-escaped.
  #
  # Options
  # * project - Project to search in.
  # * field - String. Issue field to key off of in the grouping.
  # * joins - String. The table name to join against.
  def self.count_and_group_by(options)
    project = options.delete(:project)
    select_field = options.delete(:field)
    joins = options.delete(:joins)

    where = "i.#{select_field}=j.id"

    ActiveRecord::Base.connection.select_all(
      "select    s.id as status_id,
        s.is_closed as closed,
        j.id as #{select_field},
        count(i.id) as total
      from
          #{WorkPackage.table_name} i, #{Status.table_name} s, #{joins} j
      where
        i.status_id=s.id
        and #{where}
        and i.project_id=#{project.id}
      group by s.id, s.is_closed, j.id"
    ).to_a
  end

  private_class_method :count_and_group_by

  def set_attachments_error_details
    if invalid_attachment = attachments.detect(&:invalid?)
      errors.messages[:attachments].first << " - #{invalid_attachment.errors.full_messages.first}"
    end
  end

  def save_agenda_item_journals
    ##
    # Meetings are stored before they become dissociated from the work package,
    # but the meeting journals are saved only after the agenda items are dissociated (nullified).
    # By saving the meeting journals, the agenda item journals are also saved.
    stored_meetings = meetings.to_a
    yield
    stored_meetings.each(&:touch_and_save_journals)
  end
end
