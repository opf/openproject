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

class Meeting < ApplicationRecord
  include VirtualStartTime
  include MeetingUid
  include ChronicDuration
  include OpenProject::Journal::AttachmentHelper

  self.table_name = "meetings"

  belongs_to :project
  belongs_to :author, class_name: "User"

  belongs_to :recurring_meeting, optional: true

  has_many :time_entries, dependent: :delete_all, inverse_of: :entity, as: :entity

  has_many :participants,
           dependent: :destroy,
           class_name: "MeetingParticipant"

  has_many :agenda_items, dependent: :destroy, class_name: "MeetingAgendaItem", inverse_of: :meeting
  has_many :sections, -> { where(backlog: false) }, dependent: :delete_all, class_name: "MeetingSection"
  has_one :own_backlog, -> { where(backlog: true) }, dependent: :destroy, class_name: "MeetingSection"

  accepts_nested_attributes_for :agenda_items

  scope :templated, -> { where(template: true) }
  scope :not_templated, -> { where(template: false) }
  scope :onetime_templates, -> { where(template: true, recurring_meeting_id: nil) }
  scope :series_templates, -> { where(template: true).where.not(recurring_meeting_id: nil) }

  scope :not_cancelled, -> { where.not.cancelled }

  scope :not_recurring, -> { where(recurring_meeting_id: nil) }
  scope :recurring, -> { where.not(recurring_meeting_id: nil) }

  # Meetings that represent an occurrence of a recurring series
  scope :recurring_occurrence, -> { not_templated.recurring }

  scope :from_tomorrow, -> { where(start_time: Date.tomorrow.beginning_of_day..) }
  scope :from_today, -> { where(start_time: Time.zone.today.beginning_of_day..) }
  scope :started, -> { where(state: [states[:in_progress], states[:closed]]) }
  scope :from_today_or_recently_started, -> { from_today.or(Meeting.started.where(start_time: Setting.ical_feed_keep_closed_meetings_days.days.ago..)) }

  scope :upcoming, -> { where("start_time + (interval '1 hour' * duration) >= ?", Time.current) }
  scope :past, -> { where("start_time + (interval '1 hour' * duration) < ?", Time.current) }

  scope :with_users_by_date, -> {
    order("#{Meeting.table_name}.title ASC")
      .includes({ participants: :user }, :author)
  }

  scope :visible, ->(*args) {
    not_cancelled
      .includes(:project)
      .references(:projects)
      .merge(Project.allowed_to(args.first || User.current, :view_meetings))
  }

  scope :allowed_to, ->(user, permission) {
    includes(:project)
      .references(:projects)
      .merge(Project.allowed_to(user, permission))
  }

  scope :participated_by, ->(user) {
    joins(:participants).where(meeting_participants: { user_id: user.id })
  }

  scope :available_onetime_templates, -> {
    onetime_templates.where(project_id: Project.active.select(:id))
  }

  acts_as_attachable(
    after_remove: :attachments_changed,
    order: "#{Attachment.table_name}.file",
    add_on_new_permission: :create_meetings,
    add_on_persisted_permission: :edit_meetings,
    view_permission: :view_meetings,
    delete_permission: :edit_meetings,
    modification_blocked: ->(*) { false }
  )

  acts_as_watchable permission: :view_meetings

  acts_as_searchable columns: [
                       "#{table_name}.title",
                       "#{MeetingAgendaItem.table_name}.title",
                       "#{MeetingAgendaItem.table_name}.notes",
                       "#{MeetingOutcome.table_name}.notes"
                     ],
                     include: [:project, { agenda_items: :outcomes }],
                     references: %i[agenda_items outcomes],
                     date_column: "#{table_name}.created_at"

  include Meeting::Journalized

  accepts_nested_attributes_for :participants, allow_destroy: true

  validates :title, :project_id, presence: true
  validates :sharing, absence: true, unless: :onetime_template?
  validates :recurrence_start_time, absence: true, if: :template?
  validates :recurrence_start_time, presence: true, if: -> { recurring? && !template? }

  validates :duration, numericality: { greater_than: 0 }

  before_save :add_new_participants_as_watcher

  after_commit :send_updated_mail, on: :update, if: -> {
    !template? &&
      (saved_change_to_start_time? || saved_change_to_duration? || saved_change_to_location? || saved_change_to_title?)
  }

  enum :state, {
    open: 0, # 0 -> default, leave values for future states between open and closed
    draft: 1,
    in_progress: 3,
    cancelled: 4,
    closed: 5
  }

  enum :sharing, {
    none: "none",
    descendants: "descendants",
    system: "system"
  }, prefix: :sharing, validate: { allow_nil: true }

  # Debounce meeting emails by one minute
  # this is currently hard coded
  def self.journal_aggregation_time_minutes
    1
  end

  def self.templates_visible_in_project(project, user = User.current)
    accessible_ids = Project.allowed_to(user, :view_meetings).select(:id)

    available_onetime_templates
      .where(project_id: project.id).where(project_id: accessible_ids)
      .or(available_onetime_templates.where(sharing: :descendants, project_id: project.ancestors.select(:id)))
      .or(available_onetime_templates.where(sharing: :system))
  end

  def self.templates_visible_globally(user = User.current)
    accessible = Project.allowed_to(user, :view_meetings).to_a
    return none if accessible.empty?

    ancestor_ids = accessible.map(&:ancestors).reduce(:or).select(:id)

    available_onetime_templates
      .where(project_id: accessible.map(&:id))
      .or(available_onetime_templates.where(sharing: :descendants, project_id: ancestor_ids))
      .or(available_onetime_templates.where(sharing: :system))
  end

  def recurring?
    recurring_meeting_id.present?
  end

  ##
  # Cache key for detecting changes to be shown to the user
  def changed_hash
    parts = Meeting
              .unscoped
              .where(id:)
              .joins("LEFT JOIN meeting_sections ON meeting_sections.meeting_id = meetings.id")
              .left_joins(:agenda_items, agenda_items: %i[outcomes meeting_section])
              .pick(
                Arel.sql("MAX(CASE WHEN meeting_sections.backlog = FALSE THEN meeting_agenda_items.updated_at END)"),
                Arel.sql("MAX(CASE WHEN meeting_sections.backlog = FALSE THEN meeting_sections.updated_at END)"),
                Arel.sql("MAX(meeting_outcomes.updated_at)")
              )

    parts << lock_version

    OpenProject::Cache::CacheKey.expand(parts)
  end

  def start_month
    start_time&.month
  end

  def start_year
    start_time&.year
  end

  def end_time
    return nil if start_time.nil?

    start_time + duration.hours
  end

  def past?
    end_time < Time.current
  end

  def to_s
    title
  end

  def templated?
    !!template
  end

  def series_template?
    template? && recurring_meeting_id.present?
  end

  def onetime_template?
    template? && recurring_meeting_id.nil?
  end

  # One-time meeting time zone
  # is always in the user's time zone
  def time_zone
    User.current.time_zone
  end

  # Returns true if user or current user is allowed to view the meeting
  def visible?(user = User.current)
    user.allowed_in_project?(:view_meetings, project)
  end

  def editable?(user = User.current)
    !closed? && user.allowed_in_project?(:edit_meetings, project)
  end

  def notify?
    return false if onetime_template?

    if recurring?
      recurring_meeting.template.notify
    else
      notify
    end
  end

  def self.group_by_time(meetings)
    by_start_year_month_date = ActiveSupport::OrderedHash.new do |hy, year|
      hy[year] = ActiveSupport::OrderedHash.new do |hm, month|
        hm[month] = ActiveSupport::OrderedHash.new
      end
    end

    meetings.group_by(&:start_year).each do |year, objs|
      objs.group_by(&:start_month).each do |month, objs|
        objs.group_by(&:start_time).each do |date, objs|
          by_start_year_month_date[year][month][date] = objs
        end
      end
    end

    by_start_year_month_date
  end

  alias :original_participants_attributes= :participants_attributes=

  def participants_attributes=(attrs)
    attrs.each do |participant|
      participant["_destroy"] = true if !(participant[:attended] || participant[:invited])
    end
    self.original_participants_attributes = attrs
  end

  # Participants of older meetings
  # might contain users no longer in the project
  #
  # This returns the set currently allowed to view the meeting
  def allowed_participants
    available_members = User.allowed_members(:view_meetings, project).select(:id)

    participants
      .where(user_id: available_members)
  end

  def agenda_items_sum_duration_in_minutes
    agenda_items.sum(:duration_in_minutes)
  end

  def duration_exceeded_by_agenda_items?
    agenda_items_sum_duration_in_minutes > (duration * 60)
  end

  def duration_exceeded_by_agenda_items_in_minutes
    agenda_items_sum_duration_in_minutes - (duration * 60)
  end

  def backlog
    if recurring? && !templated?
      recurring_meeting.template.backlog
    else
      own_backlog
    end
  end

  def send_emails?
    return false if onetime_template?
    return false if template? && recurring_meeting.meetings.not_templated.not_cancelled.none?
    return false if closed? || cancelled?

    persisted? && notify?
  end

  # Override virtual_start_time methods for onetime templates
  def set_initial_values
    return if onetime_template?

    super
  end

  def validate_date_and_time
    return if onetime_template?

    super
  end

  private

  def add_new_participants_as_watcher
    participants.select(&:new_record?).each do |p|
      add_watcher(p.user)
    end
  end

  def send_updated_mail
    return unless send_emails?

    Meetings::NotificationDebounceJob.debounce(
      self,
      since_journal_id: last_journal&.predecessor&.id,
      since_invited_ids: participants.invited.pluck(:user_id),
      since_attributes: updated_mail_since_attributes
    )
  end

  def updated_mail_since_attributes
    %w[title location start_time duration].index_with do |attribute|
      value = saved_change_to_attribute(attribute)&.first || public_send(attribute)
      value.respond_to?(:iso8601) ? value.iso8601 : value
    end
  end
end
