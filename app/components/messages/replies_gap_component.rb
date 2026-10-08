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
  class RepliesGapComponent < ApplicationComponent
    def self.dom_id(after_id, before_id) = "forum-thread-gap-#{after_id}-#{before_id}"

    def initialize(topic:, gap:, focus: false)
      super
      @topic = topic
      @gap = gap
      @focus = focus
    end

    def call
      render(Primer::Box.new(id: self.class.dom_id(gap.after_id, gap.before_id), test_selector: "forum-thread-gap")) do
        safe_join([render(Primer::Box.new(classes: "op-forum-thread-gap--ellipsis")), load_button])
      end
    end

    private

    attr_reader :topic, :gap

    def load_button
      render(Primer::Beta::Button.new(tag: :a, href: load_path, autofocus: @focus, data: { turbo_stream: true })) do |button|
        button.with_leading_visual_icon(icon: :eye)
        label
      end
    end

    def label
      page_size = Messages::ThreadLayout::PAGE_SIZE
      if gap.count > page_size
        t("forums.topic.gap.load_previous_page", count: page_size, total: gap.count)
      else
        t("forums.topic.gap.load_previous", count: gap.count)
      end
    end

    def load_path
      replies_project_forum_topic_path(topic.project, topic.forum, topic, after: gap.after_id, before: gap.before_id)
    end
  end
end
