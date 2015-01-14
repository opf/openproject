#-- copyright
# OpenProject Meeting Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++

class Meeting < ActiveRecord::Base
  self.table_name = 'meetings'

  belongs_to :project
  belongs_to :author, class_name: 'User', foreign_key: 'author_id'
  has_one :agenda, dependent: :destroy, class_name: 'MeetingAgenda'
  has_one :minutes, dependent: :destroy, class_name: 'MeetingMinutes'
  has_many :contents, class_name: 'MeetingContent', readonly: true
  has_many :participants, dependent: :destroy, class_name: 'MeetingParticipant'

  default_scope order("#{Meeting.table_name}.start_time DESC")
  scope :from_tomorrow, conditions: ['start_time >= ?', Date.tomorrow.beginning_of_day]
  scope :with_users_by_date, order("#{Meeting.table_name}.title ASC")
    .includes({ participants: :user }, :author)

  attr_accessible :title, :location, :start_time, :duration

  acts_as_watchable

  acts_as_searchable columns: ["#{table_name}.title", "#{MeetingContent.table_name}.text"],
                     include: [:contents, :project],
                     date_column: "#{table_name}.created_at"

  acts_as_journalized
  acts_as_event title: Proc.new {|o|
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

  validates_presence_of :title, :start_time, :duration

  before_save :add_new_participants_as_watcher

  after_initialize :set_initial_values

  User.before_destroy do |user|
    Meeting.update_all ['author_id = ?', DeletedUser.first.id], ['author_id = ?', user.id]
  end

  def start_date
    # the text_field + calendar_for form helpers expect a Date
    start_time.to_date if start_time.present?
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
                              project.users.all(include: { memberships: [:roles, :project] }).select { |u| self.visible?(u) }

    changeable_participants.uniq(&:id)
  end

  def copy(attrs)
    copy = dup

    copy.author = attrs.delete(:author)
    copy.attributes = attrs
    copy.send(:set_initial_values)

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

        objs.group_by(&:start_date).each do |date, objs|

          by_start_year_month_date[year][month][date] = objs

        end

      end

    end

    by_start_year_month_date
  end

  def close_agenda_and_copy_to_minutes!
    agenda.lock!
    create_minutes(text: agenda.text, comment: 'Minutes created')
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
    self.start_time ||= Date.tomorrow + 10.hours
    self.duration   ||= 1
  end

  private

  def add_new_participants_as_watcher
    participants.select(&:new_record?).each do |p|
      add_watcher(p.user)
    end
  end
end
