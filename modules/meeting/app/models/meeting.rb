#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

class Meeting < ApplicationRecord
  include VirtualAttribute

  self.table_name = 'meetings'

  belongs_to :project
  belongs_to :author, class_name: 'User', foreign_key: 'author_id'
  has_one :agenda, dependent: :destroy, class_name: 'MeetingAgenda'
  has_one :minutes, dependent: :destroy, class_name: 'MeetingMinutes'
  has_many :contents, -> { readonly }, class_name: 'MeetingContent'
  has_many :participants, dependent: :destroy, class_name: 'MeetingParticipant'

  default_scope {
    order("#{Meeting.table_name}.start_time DESC")
  }
  scope :from_tomorrow, -> { where(['start_time >= ?', Date.tomorrow.beginning_of_day]) }
  scope :with_users_by_date, -> {
    order("#{Meeting.table_name}.title ASC")
      .includes({ participants: :user }, :author)
  }

  acts_as_watchable

  acts_as_searchable columns: ["#{table_name}.title", "#{MeetingContent.table_name}.text"],
                     include: [:contents, :project],
                     references: :meeting_contents,
                     date_column: "#{table_name}.created_at"

  acts_as_journalized
  acts_as_event title: Proc.new { |o|
    "#{l :label_meeting}: #{o.title} \
                 #{format_date o.start_time} \
                 #{format_time o.start_time, false}-#{format_time o.end_time, false})"
  },
                url: Proc.new { |o| { controller: '/meetings', action: 'show', id: o } },
                author: Proc.new(&:user),
                description: ''

  register_on_journal_formatter(:plaintext, 'title')
  register_on_journal_formatter(:fraction, 'duration')
  register_on_journal_formatter(:datetime, 'start_time')
  register_on_journal_formatter(:plaintext, 'location')

  accepts_nested_attributes_for :participants, allow_destroy: true

  validates_presence_of :title, :duration

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

  User.before_destroy do |user|
    Meeting.where(['author_id = ?', user.id]).update_all ['author_id = ?', DeletedUser.first.id]
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
    participants.build(user: user, invited: true) if self.new_record? && participants.empty? && user
  end

  # Returns true if usr or current user is allowed to view the meeting
  def visible?(user = nil)
    (user || User.current).allowed_to?(:view_meetings, project)
  end

  def all_changeable_participants
    changeable_participants = participants.select(&:invited).collect(&:user)
    changeable_participants = changeable_participants + participants.select(&:attended).collect(&:user)
    changeable_participants = changeable_participants + \
                              User.allowed_members(:view_meetings, project)

    changeable_participants.uniq(&:id)
  end

  def copy(attrs)
    copy = dup

    # Called simply to initialize the value
    copy.start_date
    copy.start_time_hour

    copy.author = attrs.delete(:author)
    copy.attributes = attrs
    copy.set_initial_values

    copy.participants.clear
    copy.participants_attributes = participants.collect(&:copy_attributes)

    copy
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
      minutes = create_minutes(text: original_text, comment: 'Minutes created', attachments: attachments.map(&:last))

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
      participant['_destroy'] = true if !(participant['attended'] || participant['invited'])
    end
    self.original_participants_attributes = attrs
  end

  protected

  def set_initial_values
    # set defaults
    write_attribute(:start_time, Date.tomorrow + 10.hours) if start_time.nil?
    self.duration ||= 1

    @start_date = start_time.to_date.iso8601
    @start_time_hour = start_time.strftime('%H:%M')
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
    else
      errors.add :start_time, :invalid if start_time.nil?
    end
  end

  ##
  # Actually sets the aggregated start_time attribute.
  def update_start_time!
    write_attribute(:start_time, start_time)
  end

  ##
  # Determines whether new raw values werde provided.
  def parse_start_time?
    !(changed & %w(start_date start_time_hour)).empty?
  end

  ##
  # Returns the parse result of both start_date and start_time_hour
  def parsed_start_time
    date = parsed_start_date
    time = parsed_start_time_hour

    if date.nil? || time.nil?
      raise ArgumentError, 'Provided composite start_time is invalid.'
    end

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
    Time.strptime(@start_time_hour, '%H:%M')
  rescue ArgumentError
    nil
  end

  def add_new_participants_as_watcher
    participants.select(&:new_record?).each do |p|
      add_watcher(p.user)
    end
  end
end
