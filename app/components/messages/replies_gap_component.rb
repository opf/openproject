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
    include OpPrimer::ComponentHelpers

    def self.dom_id(after_id, before_id) = "forum-thread-gap-#{after_id}-#{before_id}"

    def initialize(topic:, gap:)
      super
      @topic = topic
      @gap = gap
    end

    private

    attr_reader :topic, :gap

    def single_step? = gap.count <= Messages::ThreadLayout::PAGE_SIZE

    def next_size = chunk_sizes.first

    def previous_size = chunk_sizes.last

    def uncovered_count = gap.count - next_size - previous_size

    def chunk_sizes
      @chunk_sizes ||= Messages::ThreadLayout.chunk_sizes(gap.count)
    end

    def branch(layout, &)
      layout.with_row(flex_layout: true, my: 1, align_items: :flex_start) do |row|
        row.with_column(classes: "op-forum-thread-gap--branch")
        row.with_column(pl: 1, &)
      end
    end

    def load_link(take, label)
      render(Primer::Beta::Link.new(href: load_path(take), data: { turbo_stream: true })) { label }
    end

    def load_path(take)
      replies_project_forum_topic_path(topic.project, topic.forum, topic,
                                       after: gap.after_id, before: gap.before_id, take:)
    end
  end
end
