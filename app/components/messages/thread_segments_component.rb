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

module Messages
  class ThreadSegmentsComponent < ApplicationComponent
    def initialize(topic:, segments:, focus_first: false)
      super
      @topic = topic
      @segments = segments
      @focus_first = focus_first
    end

    def call
      safe_join(@segments.map { render_segment(it) })
    end

    private

    def render_segment(segment)
      case segment
      in Messages::ThreadLayout::Replies(messages:)
        safe_join(messages.map { render(Messages::PostComponent.new(message: it, focus: focused?(it))) })
      in Messages::ThreadLayout::Gap
        render(Messages::RepliesGapComponent.new(topic: @topic, gap: segment))
      end
    end

    def focused?(message)
      @focus_first && message == first_message
    end

    def first_message
      @segments.grep(Messages::ThreadLayout::Replies).first&.messages&.first
    end
  end
end
