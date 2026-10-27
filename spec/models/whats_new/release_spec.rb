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
    expect(release.video_url).to eq("https://www.openproject.org/release-videos/99-1?go_to_locale=en")
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

  it "keeps only the read items of the latest version" do
    user.pref.mark_whats_new_read("99_0", "old")
    user.pref.mark_whats_new_read(release.version_key, "first")

    expect(user.pref.whats_new_read_items).to eq(release.version_key => %w[first])
  end

  it "is seen by a user once the user opened its version" do
    expect(release).not_to be_seen(user)

    user.pref.mark_whats_new_seen("99_0")

    expect(release).not_to be_seen(user)

    user.pref.mark_whats_new_seen(release.version_key)

    expect(release).to be_seen(user)
  end

  it "remembers when the user first opened its version" do
    user.pref.mark_whats_new_read("99_0", "old")

    travel_to(2.days.ago) { user.pref.mark_whats_new_seen(release.version_key) }
    first_opened_at = user.pref.whats_new_seen_at
    user.pref.mark_whats_new_seen(release.version_key)

    expect(user.pref.whats_new_seen_at).to eq(first_opened_at)
    expect(user.pref.whats_new_read_items).to be_empty
  end

  it "uses the minor release of the current version" do
    stub_const("OpenProject::VERSION::PATCH", 3)

    expect(described_class.current.version)
      .to eq("#{OpenProject::VERSION::MAJOR}.#{OpenProject::VERSION::MINOR}")
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

    it "is visible for seven days after the user first opened it" do
      travel_to(7.days.ago + 1.minute) { user.pref.mark_whats_new_seen(release.version_key) }

      expect(release).to be_visible_to(user)
    end

    it "is not visible later than seven days after the user first opened it" do
      travel_to(8.days.ago) { user.pref.mark_whats_new_seen(release.version_key) }

      expect(release).not_to be_visible_to(user)
    end

    it "is visible again for a new version" do
      travel_to(8.days.ago) { user.pref.mark_whats_new_seen("99_0") }

      expect(release).to be_visible_to(user)
    end
  end
end
