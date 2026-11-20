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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Messages
  class ThreadSegmentsComponent < ApplicationComponent
    def initialize(topic:, segments:, created_work_packages: {}, focus_first: false)
      super
      @topic = topic
      @segments = segments
      @created_work_packages = created_work_packages
      @focus_first = focus_first
    end

    def call
      safe_join(@segments.map { render_segment(it) })
    end

    private

    def render_segment(segment)
      focus = @focus_first && segment == @segments.first
      case segment
      in Messages::ThreadLayout::Replies(messages:)
        safe_join(messages.map do |message|
          render(Messages::PostComponent.new(message:,
                                             work_packages: @created_work_packages.fetch(message.id, []),
                                             focus: focus && message == messages.first))
        end)
      in Messages::ThreadLayout::Gap
        render(Messages::RepliesGapComponent.new(topic: @topic, gap: segment, focus:))
      end
    end
  end
end
