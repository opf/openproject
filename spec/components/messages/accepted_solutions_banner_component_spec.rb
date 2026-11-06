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

require "rails_helper"

RSpec.describe Messages::AcceptedSolutionsBannerComponent, type: :component do
  subject(:rendered_component) { render_inline(described_class.new(topic:)) }

  shared_let(:forum) { create(:forum) }
  shared_let(:topic) { create(:message, forum:) }
  shared_let(:alice) { create(:user, firstname: "Alice", lastname: "Author") }

  current_user { create(:user, member_with_permissions: { forum.project => %i[view_messages] }) }

  it "renders nothing without an accepted solution" do
    create(:message, forum:, parent: topic)

    expect(rendered_component.to_html).to be_empty
  end

  context "with one accepted solution" do
    let!(:solution) do
      create(:message, forum:, parent: topic, author: alice, accepted_solution: true, created_at: Time.zone.local(2026, 10, 3, 9))
    end

    it "links to it by author and date, through the topic so a hidden reply still shows", :aggregate_failures do
      expect(rendered_component)
        .to have_test_selector("accepted-solutions-banner", text: "Accepted solution: Alice Author, 10/03/2026")
      expect(rendered_component)
        .to have_link("Alice Author, 10/03/2026", href: %r{/topics/#{topic.id}\?r=#{solution.id}#message-#{solution.id}\z})
    end
  end

  context "with several accepted solutions" do
    let(:bob) { create(:user, firstname: "Bob", lastname: "Replier") }

    before do
      create(:message, forum:, parent: topic, author: bob, accepted_solution: true, created_at: Time.zone.local(2026, 10, 5, 9))
      create(:message, forum:, parent: topic, author: alice, accepted_solution: true, created_at: Time.zone.local(2026, 10, 3, 9))
    end

    it "lists them oldest first on one line" do
      expect(rendered_component)
        .to have_test_selector("accepted-solutions-banner",
                               text: "Accepted solutions: Alice Author, 10/03/2026 · Bob Replier, 10/05/2026")
    end
  end

  context "when the solution's author is gone" do
    before do
      create(:message, forum:, parent: topic, accepted_solution: true, created_at: Time.zone.local(2026, 10, 3, 9))
        .update_column(:author_id, nil)
    end

    it "links to it by date alone" do
      expect(rendered_component).to have_link("10/03/2026", exact: true)
    end
  end
end
