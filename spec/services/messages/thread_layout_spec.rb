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

require "spec_helper"

RSpec.describe Messages::ThreadLayout do
  shared_let(:forum) { create(:forum) }
  shared_let(:topic) { create(:message, forum:) }

  let(:layout) { described_class.new(topic, page_size: 3) }

  def create_replies(count)
    Array.new(count) { |i| create(:message, forum:, parent: topic, created_at: topic.created_at + i.minutes + 1.minute) }
  end

  def describe_segments(segments)
    segments.map do |segment|
      case segment
      in Messages::ThreadLayout::Replies(messages:) then messages.map(&:id)
      in Messages::ThreadLayout::Gap(after_id:, before_id:, count:) then [:gap, after_id, before_id, count]
      end
    end
  end

  describe "#segments" do
    it "renders nothing for a topic without replies" do
      expect(layout.segments).to eq([])
    end

    it "renders a short thread whole" do
      replies = create_replies(3)

      expect(describe_segments(layout.segments)).to eq([replies.map(&:id)])
    end

    it "hides the replies before the latest page behind one gap" do
      replies = create_replies(7)

      expect(describe_segments(layout.segments)).to eq(
        [[:gap, topic.id, replies[4].id, 4], replies[4..].map(&:id)]
      )
    end

    it "renders a target's page between two gaps" do
      replies = create_replies(10)

      expect(describe_segments(layout.segments(target_id: replies[4].id))).to eq(
        [
          [:gap, topic.id, replies[3].id, 3],
          replies[3..5].map(&:id),
          [:gap, replies[5].id, replies[7].id, 1],
          replies[7..].map(&:id)
        ]
      )
    end

    it "merges a target on the latest page" do
      replies = create_replies(7)

      expect(describe_segments(layout.segments(target_id: replies[6].id))).to eq(
        [[:gap, topic.id, replies[4].id, 4], replies[4..].map(&:id)]
      )
    end

    it "renders the first page for a target there" do
      replies = create_replies(10)

      expect(describe_segments(layout.segments(target_id: replies[1].id))).to eq(
        [replies[0..2].map(&:id), [:gap, replies[2].id, replies[7].id, 4], replies[7..].map(&:id)]
      )
    end

    it "ignores an unknown target" do
      replies = create_replies(7)

      expect(describe_segments(layout.segments(target_id: "999999"))).to eq(
        [[:gap, topic.id, replies[4].id, 4], replies[4..].map(&:id)]
      )
    end
  end

  describe ".chunk_sizes" do
    it "loads a gap of a page or less at once from either side" do
      expect(described_class.chunk_sizes(2, page_size: 3)).to eq([2, 2])
    end

    it "splits a gap of up to two pages in halves, the next half taking the odd reply", :aggregate_failures do
      expect(described_class.chunk_sizes(5, page_size: 3)).to eq([3, 2])
      expect(described_class.chunk_sizes(6, page_size: 3)).to eq([3, 3])
    end

    it "loads a page from either side of a longer gap" do
      expect(described_class.chunk_sizes(7, page_size: 3)).to eq([3, 3])
    end
  end

  describe "#gap_segments" do
    let!(:replies) { create_replies(10) }

    it "loads the next page right after the upper bound" do
      expect(describe_segments(layout.gap_segments(after_id: topic.id, before_id: replies[7].id, take: "next"))).to eq(
        [replies[0..2].map(&:id), [:gap, replies[2].id, replies[7].id, 4]]
      )
    end

    it "loads the previous page right before the lower bound" do
      expect(describe_segments(layout.gap_segments(after_id: topic.id, before_id: replies[7].id, take: "previous"))).to eq(
        [[:gap, topic.id, replies[4].id, 4], replies[4..6].map(&:id)]
      )
    end

    it "loads the larger half of a gap of up to two pages from the upper bound" do
      expect(describe_segments(layout.gap_segments(after_id: topic.id, before_id: replies[5].id, take: "next"))).to eq(
        [replies[0..2].map(&:id), [:gap, replies[2].id, replies[5].id, 2]]
      )
    end

    it "loads the smaller half of a gap of up to two pages from the lower bound" do
      expect(describe_segments(layout.gap_segments(after_id: topic.id, before_id: replies[5].id, take: "previous"))).to eq(
        [[:gap, topic.id, replies[3].id, 3], replies[3..4].map(&:id)]
      )
    end

    it "loads everything for take all" do
      expect(describe_segments(layout.gap_segments(after_id: replies[2].id, before_id: replies[7].id, take: "all"))).to eq(
        [replies[3..6].map(&:id)]
      )
    end

    it "loads strictly inside the bounds" do
      loaded = layout.gap_segments(after_id: replies[2].id, before_id: replies[5].id, take: "next")

      expect(describe_segments(loaded)).to eq([replies[3..4].map(&:id)])
    end

    it "treats a missing bound as the open end of the thread" do
      loaded = layout.gap_segments(after_id: "999999", before_id: "", take: "all")

      expect(describe_segments(loaded)).to eq([replies.map(&:id)])
    end
  end
end
