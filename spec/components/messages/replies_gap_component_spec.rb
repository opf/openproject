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

require "rails_helper"

RSpec.describe Messages::RepliesGapComponent, type: :component do
  subject(:rendered_component) { render_inline(described_class.new(topic:, gap:)) }

  shared_let(:forum) { create(:forum) }
  shared_let(:topic) { create(:message, forum:) }

  let(:path) { "/projects/#{forum.project.identifier}/forums/#{forum.id}/topics/#{topic.id}/replies" }

  before { topic.update_column(:replies_count, 52) }

  context "when hiding more than two pages" do
    let(:gap) { Messages::ThreadLayout::Gap.new(after_id: topic.id, before_id: 63, count: 45) }

    it "offers loading a page from either side around the replies neither loads", :aggregate_failures do
      expect(rendered_component).to have_css("#forum-thread-gap-#{topic.id}-63")
      expect(rendered_component).to have_link("Load next 20 replies",
                                              href: "#{path}?after=#{topic.id}&before=63&take=next")
      expect(rendered_component).to have_text(/(?<!\d)5 of 52 replies in between/)
      expect(rendered_component).to have_link("Load previous 20 replies",
                                              href: "#{path}?after=#{topic.id}&before=63&take=previous")
    end

    it "loads through Turbo streams" do
      expect(rendered_component).to have_css("a[data-turbo-stream]", count: 2)
    end
  end

  context "when hiding up to two pages" do
    let(:gap) { Messages::ThreadLayout::Gap.new(after_id: topic.id, before_id: 63, count: 33) }

    it "splits them between both sides, the next half taking the odd reply", :aggregate_failures do
      expect(rendered_component).to have_link("Load next 17 replies")
      expect(rendered_component).to have_link("Load previous 16 replies")
      expect(rendered_component).to have_no_text("in between")
    end
  end

  context "when hiding a page or less" do
    let(:gap) { Messages::ThreadLayout::Gap.new(after_id: 20, before_id: 25, count: 4) }

    it "offers showing them all at once", :aggregate_failures do
      expect(rendered_component).to have_link("Load the 4 replies in between", href: "#{path}?after=20&before=25&take=all")
      expect(rendered_component).to have_no_link("Load next 20 replies")
    end
  end
end
