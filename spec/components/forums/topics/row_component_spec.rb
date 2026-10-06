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

RSpec.describe Forums::Topics::RowComponent, type: :component do
  subject(:rendered_component) do
    render_inline(described_class.new(row: topic, table:))
  end

  shared_let(:forum) { create(:forum) }

  let(:table) { Forums::Topics::TableComponent.new(rows: forum.topics, forum:) }
  let(:topic) { create(:message, forum:, subject: "Release planning") }

  it "links the subject to the topic" do
    expect(rendered_component)
      .to have_link("Release planning", href: "/projects/#{forum.project.identifier}/forums/#{forum.id}/topics/#{topic.id}")
  end

  context "when sticky and locked" do
    let(:topic) { create(:message, forum:, sticky: true, locked: true) }

    it "marks both with a labelled icon", :aggregate_failures do
      expect(rendered_component).to have_css("[data-test-selector='topic-sticky'][aria-label='Sticky']")
      expect(rendered_component).to have_css("[data-test-selector='topic-locked'][aria-label='Locked']")
    end
  end

  context "with a last reply" do
    before do
      create(:message, forum:, parent: topic, subject: "RE: Release planning")
      topic.reload
    end

    it "links the last reply" do
      expect(rendered_component).to have_link("RE: Release planning")
    end

    it "gives the last reply a cell that does not clip its byline" do
      # The byline holds an author and a timestamp on its own line, which an ellipsis cell clips mid-date.
      expect(rendered_component).to have_css(".last_reply:not(.ellipsis)", text: "RE: Release planning")
    end

    it "leaves the last reply out of the stacked phone layout" do
      expect(rendered_component).to have_css(".last_reply.op-border-box-grid__row-item--no-mobile", text: "RE: Release planning")
    end
  end

  context "when the author is gone" do
    before { topic.update_column(:author_id, nil) }

    it "renders the row without an author" do
      expect(rendered_component).to have_link("Release planning")
    end
  end
end
