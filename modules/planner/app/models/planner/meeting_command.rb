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

module Planner
  # A task written as "Set up a /meeting with @sakura about wiki permissions": the meeting it asks
  # for, with the mentioned people as participants and the text after "about" as the title.
  class MeetingCommand
    COMMAND = %r{(?<!\S)/meeting\b}
    MENTION = /(?<![\w@])@([\w.-]+)/
    TOPIC = /\babout\s+(.+)\z/i

    attr_reader :subject, :user

    def self.for(work_package, user)
      new(work_package.subject, user) if work_package.subject.match?(COMMAND)
    end

    def initialize(subject, user)
      @subject = subject
      @user = user
    end

    def participants
      @participants ||= User.visible(user).active.where(login: subject.scan(MENTION).flatten).to_a
    end

    def title
      topic = subject[TOPIC, 1]
      return topic.strip.upcase_first if topic
      return I18n.t("planner.meeting_with", names: participants.map(&:name).to_sentence) if participants.any?

      subject.gsub(COMMAND, "").squish.upcase_first
    end
  end
end
