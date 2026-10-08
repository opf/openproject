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
  subject(:rendered_component) { render_inline(described_class.new(topic:, gap:, focus: focused)) }

  shared_let(:forum) { create(:forum) }
  shared_let(:topic) { create(:message, forum:) }

  let(:path) { "/projects/#{forum.project.identifier}/forums/#{forum.id}/topics/#{topic.id}/replies" }
  let(:focused) { false }

  context "when hiding more than a page" do
    let(:gap) { Messages::ThreadLayout::Gap.new(after_id: topic.id, before_id: 63, count: 45) }

    it "offers loading the previous page, out of all it hides", :aggregate_failures do
      expect(rendered_component).to have_css("#forum-thread-gap-#{topic.id}-63")
      expect(rendered_component).to have_link("Load previous 20 replies (out of 45)", href: "#{path}?after=#{topic.id}&before=63")
    end

    it "loads through a Turbo stream" do
      expect(rendered_component).to have_css("a[data-turbo-stream]", count: 1)
    end

    it "leaves focus alone on a page render" do
      expect(rendered_component).to have_no_css("[autofocus]")
    end
  end

  context "when hiding a page or less" do
    let(:gap) { Messages::ThreadLayout::Gap.new(after_id: 20, before_id: 25, count: 4) }

    it "offers loading them all", :aggregate_failures do
      expect(rendered_component).to have_link("Load previous 4 replies", href: "#{path}?after=20&before=25")
      expect(rendered_component).to have_no_text("out of")
    end
  end

  context "when hiding a single reply" do
    let(:gap) { Messages::ThreadLayout::Gap.new(after_id: 20, before_id: 22, count: 1) }

    it "offers loading it" do
      expect(rendered_component).to have_link("Load previous reply")
    end
  end

  context "when streamed in after a click" do
    let(:gap) { Messages::ThreadLayout::Gap.new(after_id: topic.id, before_id: 63, count: 45) }
    let(:focused) { true }

    it "takes focus so the next page is one key press away" do
      expect(rendered_component).to have_css("a[autofocus]", text: "Load previous 20 replies")
    end
  end
end
