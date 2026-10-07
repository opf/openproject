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

RSpec.describe Messages::ThreadSegmentsComponent, type: :component do
  subject(:rendered_component) { render_inline(described_class.new(topic:, segments:, focus_first:)) }

  shared_let(:forum) { create(:forum) }
  shared_let(:topic) { create(:message, forum:) }
  shared_let(:replies) { create_list(:message, 2, forum:, parent: topic) }

  let(:focus_first) { false }
  let(:segments) do
    [
      Messages::ThreadLayout::Replies.new(messages: replies),
      Messages::ThreadLayout::Gap.new(after_id: replies.last.id, before_id: nil, count: 3)
    ]
  end

  current_user { create(:user, member_with_permissions: { forum.project => %i[view_messages] }) }

  it "renders the replies, then the gap", :aggregate_failures do
    expect(rendered_component).to have_css("#message-#{replies.first.id}")
    expect(rendered_component).to have_css("#message-#{replies.last.id} ~ [data-test-selector='forum-thread-gap']")
  end

  it "focuses nothing on a page render" do
    expect(rendered_component).to have_no_css("[autofocus]")
  end

  context "when streamed in after a click" do
    let(:focus_first) { true }

    it "focuses the first newly shown reply only" do
      expect(rendered_component).to have_css("[autofocus]", count: 1)
      expect(rendered_component).to have_css("#message-#{replies.first.id}[autofocus][tabindex='-1']")
    end
  end
end
