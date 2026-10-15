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

RSpec.describe WhatsNew::Release do
  subject(:release) { described_class.new(major: 99, minor: 1) }

  let(:user) { create(:user) }

  before do
    I18n.backend.store_translations(
      :en,
      homescreen: {
        blocks: {
          new_features: {
            "99_1": {
              new_features_list: {
                first: { title: "First", description: "The first one", url: "https://example.com/first" },
                second: { title: "Second", description: "The second one", url: "https://example.com/second" }
              },
              whats_new: {
                video_url: "https://example.com/video"
              }
            },
            "99_3": {
              new_features_list: {
                teaser: { title: "Teaser", description: "Only in the teaser", url: "https://example.com/teaser" }
              },
              whats_new: {
                items: {
                  own: { title: "Own", description: "Only in What's new", url: "https://example.com/own" }
                }
              }
            }
          }
        }
      }
    )
  end

  it "uses the new features of its version as items" do
    expect(release.items).to eq(release.features)
    expect(release.items).to eq(
      [
        described_class::Item.new(key: "first", title: "First", description: "The first one",
                                  url: "https://example.com/first"),
        described_class::Item.new(key: "second", title: "Second", description: "The second one",
                                  url: "https://example.com/second")
      ]
    )
    expect(release.video_url).to eq("https://example.com/video")
    expect(release.version).to eq("99.1")
  end

  it "prefers its own items over the new features" do
    release = described_class.new(major: 99, minor: 3)

    expect(release.features.map(&:key)).to eq(%w[teaser])
    expect(release.items.map(&:key)).to eq(%w[own])
  end

  it "has no items for a version without translations" do
    expect(described_class.new(major: 99, minor: 2).items).to be_empty
  end

  it "tracks the read items of a user" do
    expect(release.unread_keys(user)).to eq(%w[first second])

    user.pref.mark_whats_new_read(release.version_key, "first")
    user.pref.mark_whats_new_read(release.version_key, "first")

    expect(release.unread_keys(user)).to eq(%w[second])
  end

  it "is seen by a user once the user opened its version" do
    expect(release).not_to be_seen(user)

    user.pref.whats_new_seen_version = "99_0"

    expect(release).not_to be_seen(user)

    user.pref.whats_new_seen_version = release.version_key

    expect(release).to be_seen(user)
  end

  describe "#visible_to?" do
    it "is visible to a logged in user" do
      expect(release).to be_visible_to(user)
    end

    it "is not visible to the anonymous user" do
      expect(release).not_to be_visible_to(User.anonymous)
    end

    it "is not visible without items" do
      expect(described_class.new(major: 99, minor: 2)).not_to be_visible_to(user)
    end
  end
end
