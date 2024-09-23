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
  include VirtualAttribute
  include OpenProject::Journal::AttachmentHelper

  self.table_name = "meetings"

  belongs_to :project
  belongs_to :author, class_name: "User"
  has_one :agenda, dependent: :destroy, class_name: "MeetingAgenda"
  has_one :minutes, dependent: :destroy, class_name: "MeetingMinutes"
  has_many :contents, -> { readonly }, class_name: "MeetingContent"

  has_many :participants,
           dependent: :destroy,
           class_name: "MeetingParticipant",
           after_add: :send_participant_added_mail

  has_many :sections, dependent: :destroy, class_name: "MeetingSection"
  has_many :agenda_items, dependent: :destroy, class_name: "MeetingAgendaItem"

  default_scope do
    order("#{Meeting.table_name}.start_time DESC")
  end
  scope :from_tomorrow, -> { where(["start_time >= ?", Date.tomorrow.beginning_of_day]) }
  scope :from_today, -> { where(["start_time >= ?", Time.zone.today.beginning_of_day]) }
  scope :with_users_by_date, -> {
    order("#{Meeting.table_name}.title ASC")
      .includes({ participants: :user }, :author)
  }
  scope :visible, ->(*args) {
    includes(:project)
      .references(:projects)
      .merge(Project.allowed_to(args.first || User.current, :view_meetings))
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
                       "#{MeetingContent.table_name}.text",
                       "#{MeetingAgendaItem.table_name}.title",
                       "#{MeetingAgendaItem.table_name}.notes"
                     ],
                     include: %i[contents project agenda_items],
                     references: %i[meeting_contents agenda_items],
                     date_column: "#{table_name}.created_at"

  include Meeting::Journalized

  accepts_nested_attributes_for :participants, allow_destroy: true

  validates_presence_of :title, :project_id, :duration

  # We only save start_time as an aggregated value of start_date and hour,
  # but still need start_date and _hour for validation purposes
  virtual_attribute :start_date do
    @start_date
  end
  virtual_attribute :start_time_hour do
    @start_time_hour
  end

  validate :validate_date_and_time

  before_save :update_start_time!
  before_save :add_new_participants_as_watcher
  after_initialize :set_initial_values
  after_update :send_rescheduling_mail, if: -> { saved_change_to_start_time? || saved_change_to_duration? }

  enum state: {
    open: 0, # 0 -> default, leave values for future states between open and closed
    closed: 5
  }

  ##
  # Cache key for detecting changes to be shown to the user
  def changed_hash
    parts = Meeting
      .unscoped
      .where(id:)
      .left_joins(:agenda_items, :sections)
      .pick(MeetingAgendaItem.arel_table[:updated_at].maximum, MeetingSection.arel_table[:updated_at].maximum)

    parts << lock_version

    OpenProject::Cache::CacheKey.expand(parts)
  end

  ##
  # Return the computed start_time when changed
  def start_time
    if parse_start_time?
      parsed_start_time
    else
      super
    end
  end

  def start_time=(value)
    super(value&.to_datetime)
    update_derived_fields
  end

  def start_month
    start_time.month
  end

  def start_year
    start_time.year
  end

  def end_time
    start_time + duration.hours
  end

  def to_s
    title
  end

  def text
    agenda.text if agenda.present?
  end

  def author=(user)
    super
    # Don't add the author as participant if we already have some through nested attributes
    participants.build(user:, invited: true) if new_record? && participants.empty? && user
  end

  # Returns true if user or current user is allowed to view the meeting
  def visible?(user = User.current)
    user.allowed_in_project?(:view_meetings, project)
  end

  def editable?(user = User.current)
    open? && user.allowed_in_project?(:edit_meetings, project)
  end

  def invited_or_attended_participants
    participants.where(invited: true).or(participants.where(attended: true))
  end

  def all_changeable_participants
    changeable_participants = participants.select(&:invited).collect(&:user)
    changeable_participants = changeable_participants + participants.select(&:attended).collect(&:user)
    changeable_participants = changeable_participants +
      User.allowed_members(:view_meetings, project)

    changeable_participants
      .compact
      .uniq(&:id)
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

  def close_agenda_and_copy_to_minutes!
    Meeting.transaction do
      agenda.lock!

      attachments = agenda.attachments.map { |a| [a, a.copy] }
      original_text = String(agenda.text)
      minutes = create_minutes(text: original_text,
                               journal_notes: I18n.t("events.meeting_minutes_created"),
                               attachments: attachments.map(&:last))

      # substitute attachment references in text to use the respective copied attachments
      updated_text = original_text.gsub(/(?<=\(\/api\/v3\/attachments\/)\d+(?=\/content\))/) do |id|
        old_id = id.to_i
        new_id = attachments.select { |a, _| a.id == old_id }.map { |_, a| a.id }.first

        new_id || -1
      end

      minutes.update text: updated_text if updated_text != original_text
    end
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

  protected

  def set_initial_values
    # set defaults
    write_attribute(:start_time, Date.tomorrow + 10.hours) if start_time.nil?
    self.duration ||= 1
    update_derived_fields
  end

  def update_derived_fields
    @start_date = start_time.to_date.iso8601
    @start_time_hour = start_time.strftime("%H:%M")
  end

  private

  ##
  # Validate date and time setters.
  # If start_time has been changed, check that value.
  # Otherwise start_{date, time_hour} was used, then validate those
  def validate_date_and_time
    if parse_start_time?
      errors.add :start_date, :not_an_iso_date if parsed_start_date.nil?
      errors.add :start_time_hour, :invalid_time_format if parsed_start_time_hour.nil?
    elsif start_time.nil?
      errors.add :start_time, :invalid
    end
  end

  ##
  # Actually sets the aggregated start_time attribute.
  def update_start_time!
    write_attribute(:start_time, start_time)
  end

  ##
  # Determines whether new raw values were provided.
  def parse_start_time?
    changed.intersect?(%w(start_date start_time_hour))
  end

  ##
  # Returns the parse result of both start_date and start_time_hour
  def parsed_start_time
    date = parsed_start_date
    time = parsed_start_time_hour

    return if date.nil? || time.nil?

    Time.zone.local(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.min
    )
  end

  ##
  # Enforce ISO 8601 date parsing for the given input string
  # This avoids weird parsing of dates due to malformed input.
  def parsed_start_date
    Date.iso8601(@start_date)
  rescue ArgumentError
    nil
  end

  ##
  # Enforce HH::MM time parsing for the given input string
  def parsed_start_time_hour
    Time.strptime(@start_time_hour, "%H:%M")
  rescue ArgumentError
    nil
  end

  def add_new_participants_as_watcher
    participants.select(&:new_record?).each do |p|
      add_watcher(p.user)
    end
  end

  def send_participant_added_mail(participant)
    if persisted? && Journal::NotificationConfiguration.active?
      MeetingMailer.invited(self, participant.user, User.current).deliver_later
    end
  end

  def send_rescheduling_mail
    MeetingNotificationService
      .new(self)
      .call :rescheduled,
            changes: {
              old_start: saved_change_to_start_time? ? saved_change_to_start_time.first : start_time,
              new_start: start_time,
              old_duration: saved_change_to_duration? ? saved_change_to_duration.first : duration,
              new_duration: duration
            }
  end
end
