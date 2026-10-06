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

RSpec.describe Forums::RowComponent, type: :component do
  subject(:rendered_component) do
    with_request_url("/projects/#{project.identifier}/forums") do
      render_inline(described_class.new(row: forum, table:))
    end
  end

  shared_let(:project) { create(:project) }
  shared_let(:above) { create(:forum, project:, name: "Above") }
  shared_let(:forum) { create(:forum, project:, name: "Support", description: "Ask <b>here</b>") }
  shared_let(:below) { create(:forum, project:, name: "Below") }

  let(:table) { Forums::TableComponent.new(rows: project.forums, project:) }

  current_user { create(:user, member_with_permissions: { project => %i[view_messages manage_forums] }) }

  it "links the forum name to the forum" do
    expect(rendered_component).to have_link("Support", href: "/projects/#{project.identifier}/forums/#{forum.id}")
  end

  it "shows the description as text, never as markup" do
    expect(rendered_component).to have_text("Ask <b>here</b>")
  end

  it "offers every move between neighbours", :aggregate_failures do
    expect(rendered_component).to have_button("Move to top")
    expect(rendered_component).to have_button("Move up")
    expect(rendered_component).to have_button("Move down")
    expect(rendered_component).to have_button("Move to bottom")
  end

  context "when the forum is first" do
    subject(:rendered_component) do
      with_request_url("/projects/#{project.identifier}/forums") do
        render_inline(described_class.new(row: above, table:))
      end
    end

    it "offers no upward move", :aggregate_failures do
      expect(rendered_component).to have_no_button("Move to top")
      expect(rendered_component).to have_no_button("Move up")
      expect(rendered_component).to have_button("Move down")
    end
  end

  context "with a last message whose author is gone" do
    before do
      message = create(:message, forum:, subject: "Orphaned post")
      message.update_column(:author_id, nil)
      forum.update_column(:last_message_id, message.id)
    end

    it "still links the last message" do
      expect(rendered_component).to have_link("Orphaned post")
    end
  end

  context "with a last message" do
    before do
      message = create(:message, forum:, subject: "Latest post")
      forum.update_column(:last_message_id, message.id)
    end

    it "gives the last message a cell that does not clip its byline" do
      # The byline holds an author and a timestamp on its own line, which an ellipsis cell clips mid-date.
      expect(rendered_component).to have_css(".last_message:not(.ellipsis)", text: "Latest post")
    end

    it "leaves the last message out of the stacked phone layout" do
      expect(rendered_component).to have_css(".last_message.op-border-box-grid__row-item--no-mobile", text: "Latest post")
    end
  end
end
