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

require "spec_helper"

RSpec.describe "Header What's new", :skip_csrf, type: :rails_request do
  let(:user) { create(:user) }
  let(:release) { WhatsNew::Release.new(major: 18, minor: 0) }
  let(:item) { WhatsNew::Release::Item.new(key: "first", title: "First & best", description: "The first one", url: "/") }
  let(:other_item) { WhatsNew::Release::Item.new(key: "second", title: "Second", description: "The second one", url: "/") }

  def stream_targets
    Nokogiri::HTML.fragment(response.body).css("turbo-stream").pluck("targets")
  end

  before do
    allow(WhatsNew::Release).to receive(:current).and_return(release)
    allow(release).to receive(:items).and_return([item, other_item])
    login_as user
  end

  context "with items for the current release" do
    it "renders the content frame with the items" do
      get header_whats_new_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(<turbo-frame id="#{Header::WhatsNewComponent.wrapper_key}"))
      expect(response.body).to include(CGI.escapeHTML(item.title))
    end

    it "renders the dialog" do
      get dialog_header_whats_new_path, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(Header::WhatsNewDialogComponent::DIALOG_ID)
    end

    it "marks a known item as read" do
      post read_header_whats_new_path, params: { key: item.key }, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(user.reload.pref.whats_new_read_keys(release.version_key)).to eq([item.key])
      expect(stream_targets).to include("[data-whats-new-dot='#{item.key}']")
    end

    it "marks the release as seen and removes the badges" do
      post seen_header_whats_new_path, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(release).to be_seen(user.reload)
      expect(user.pref.whats_new_seen_at).to be_within(1.minute).of(Time.current)
      expect(stream_targets).to eq(["[data-whats-new-badge]"])
    end

    it "keeps the time of the first opening" do
      travel_to(3.days.ago) { post seen_header_whats_new_path, as: :turbo_stream }
      first_opened_at = user.reload.pref.whats_new_seen_at

      post seen_header_whats_new_path, as: :turbo_stream

      expect(user.reload.pref.whats_new_seen_at).to eq(first_opened_at)
    end

    it "keeps the badges when an item is read" do
      post read_header_whats_new_path, params: { key: item.key }, as: :turbo_stream

      expect(stream_targets).not_to include("[data-whats-new-badge]")
    end

    it "rejects an unknown item" do
      post read_header_whats_new_path, params: { key: "unknown" }, as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.reload.pref.whats_new_read_keys(release.version_key)).to be_empty
    end

    context "when anonymous" do
      let(:user) { User.anonymous }

      it "redirects to the login" do
        get header_whats_new_path

        expect(response).to redirect_to(%r{/login})
      end
    end
  end

  context "when the user first opened the release more than seven days ago" do
    before do
      user.pref.mark_whats_new_seen(release.version_key)
      user.pref.whats_new_seen_at = 8.days.ago
      user.pref.save!
    end

    it "responds with not found" do
      get header_whats_new_path

      expect(response).to have_http_status(:not_found)
    end
  end

  context "without items for the current release" do
    before do
      allow(release).to receive(:items).and_return([])
    end

    it "responds with not found" do
      get header_whats_new_path

      expect(response).to have_http_status(:not_found)
    end

    it "does not mark the release as seen" do
      post seen_header_whats_new_path, as: :turbo_stream

      expect(response).to have_http_status(:not_found)
    end

    it "does not mark items as read" do
      post read_header_whats_new_path, params: { key: item.key }, as: :turbo_stream

      expect(response).to have_http_status(:not_found)
    end
  end
end
