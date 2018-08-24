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

# Because of the WikiDiff class defined therein
require 'wiki_page'

class MeetingContent < ActiveRecord::Base
  belongs_to :meeting
  belongs_to :author, class_name: 'User', foreign_key: 'author_id'

  attr_accessor :comment

  validates_length_of :comment, maximum: 255, allow_nil: true

  before_save :comment_to_journal_notes

  acts_as_journalized
  acts_as_event type: Proc.new { |o| "#{o.class.to_s.underscore.dasherize}" },
                title: Proc.new { |o| "#{o.class.model_name.human}: #{o.meeting.title}" },
                url: Proc.new { |o| { controller: '/meetings', action: 'show', id: o.meeting } }

  User.before_destroy do |user|
    MeetingContent.where(['author_id = ?', user.id]).update_all ['author_id = ?', DeletedUser.first]
  end

  def editable?
    true
  end

  def diff(version_to = nil, version_from = nil)
    version_to = version_to ? version_to.to_i : version
    version_from = version_from ? version_from.to_i : version_to - 1
    version_to, version_from = version_from, version_to unless version_from < version_to

    content_to = journals.find_by_version(version_to)
    content_from = journals.find_by_version(version_from)

    (content_to && content_from) ? ::WikiDiff.new(content_to, content_from) : nil
  end

  def at_version(version)
    journals
      .joins("JOIN meeting_contents ON meeting_contents.id = journals.journable_id AND meeting_contents.type='#{self.class}'")
      .where(version: version)
      .first.data
  end

  # Compatibility for mailer.rb
  def updated_on
    updated_at
  end

  # Show the project on activity and search views
  def project
    meeting.project
  end

  private

  def comment_to_journal_notes
    add_journal(author, comment) unless changes.empty?
  end
end
