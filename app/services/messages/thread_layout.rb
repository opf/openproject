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
  class ThreadLayout
    PAGE_SIZE = 20

    Replies = Data.define(:messages)
    Gap = Data.define(:after_id, :before_id, :count)

    def initialize(topic, page_size: PAGE_SIZE)
      @topic = topic
      @page_size = page_size
    end

    def segments(target_id: nil)
      shown = latest_indices | target_indices(target_id)
      build(shown, from: 0, to: reply_ids.size - 1)
    end

    def gap_segments(after_id:, before_id:)
      first = first_index_after(after_id)
      last = last_index_before(before_id)
      build((first..last).to_a.last(page_size), from: first, to: last)
    end

    private

    attr_reader :topic, :page_size

    def reply_ids
      @reply_ids ||= topic.children.reorder(:created_at, :id).pluck(:id)
    end

    def latest_indices
      ([reply_ids.size - page_size, 0].max...reply_ids.size).to_a
    end

    def target_indices(target_id)
      index = reply_ids.index(target_id.to_i)
      return [] unless index

      start = (index / page_size) * page_size
      (start...[start + page_size, reply_ids.size].min).to_a
    end

    def first_index_after(after_id)
      index = reply_ids.index(after_id.to_i)
      index ? index + 1 : 0
    end

    def last_index_before(before_id)
      index = reply_ids.index(before_id.to_i)
      index ? index - 1 : reply_ids.size - 1
    end

    def build(shown_indices, from:, to:)
      shown = shown_indices.to_set
      messages = load_messages(shown_indices)

      (from..to)
        .chunk_while { |a, b| shown.include?(a) == shown.include?(b) }
        .map { |run| shown.include?(run.first) ? Replies.new(messages: run.map { messages.fetch(reply_ids[it]) }) : gap(run) }
    end

    def gap(run)
      after_id = run.first.zero? ? topic.id : reply_ids[run.first - 1]
      Gap.new(after_id:, before_id: reply_ids[run.last + 1], count: run.size)
    end

    def load_messages(indices)
      Message
        .where(id: reply_ids.values_at(*indices))
        .includes(:author, :attachments, :parent, :project, forum: :project)
        .index_by(&:id)
    end
  end
end
