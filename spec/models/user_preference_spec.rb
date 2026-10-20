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

RSpec.describe UserPreference do
  subject(:preference) do
    build(:user_preference,
          user:,
          settings: preferences)
  end

  let(:preferences) { {} }

  let(:user) { build_stubbed(:user) }

  shared_examples "accepts real and false booleans" do |setter, getter|
    it "accepts true boolean" do
      subject.send(setter, true)
      expect(subject.send(getter)).to be true

      subject.send(setter, false)
      expect(subject.send(getter)).to be false
    end

    it "accepts false booleans" do
      %w(true 1).each do |str|
        subject.send(setter, str)
        expect(subject.send(getter)).to be true
      end

      %w(false 0).each do |str|
        subject.send(setter, str)
        expect(subject.send(getter)).to be false
      end
    end
  end

  describe "sort order" do
    it_behaves_like "accepts real and false booleans",
                    :comments_in_reverse_order=,
                    :comments_in_reverse_order?

    it "can be changed by string" do
      subject.comments_sorting = "desc"
      expect(subject.comments_in_reverse_order?).to be true

      subject.comments_sorting = "asc"
      expect(subject.comments_in_reverse_order?).to be false
    end
  end

  describe "warn on unsaved changes" do
    it_behaves_like "accepts real and false booleans",
                    :warn_on_leaving_unsaved=,
                    :warn_on_leaving_unsaved?
  end

  describe "require double click for inline edit" do
    it_behaves_like "accepts real and false booleans",
                    :require_double_click_for_inline_edit=,
                    :require_double_click_for_inline_edit?

    it "is disabled without a value being stored" do
      expect(subject.require_double_click_for_inline_edit).to be false
    end
  end

  describe "auto hide popups" do
    it_behaves_like "accepts real and false booleans",
                    :auto_hide_popups=,
                    :auto_hide_popups?

    describe "without a value being stored and with default setting auto_hide_popups to false",
             with_settings: { default_auto_hide_popups: false } do
      it "disables auto hide popups" do
        expect(subject.auto_hide_popups).to be_falsey
      end
    end

    context "without a value being stored and with default setting auto_hide_popups to true",
            with_settings: { default_auto_hide_popups: true } do
      it "disables auto hide popups" do
        expect(subject.auto_hide_popups).to be_truthy
      end
    end
  end

  describe "#diff_type" do
    it "can be set and written" do
      expect(subject.diff_type)
        .to eql "inline"

      subject.diff_type = "sbs"

      expect(subject.diff_type)
        .to eql "sbs"
    end

    context "with a new pref instance" do
      subject { described_class.new }

      it "defaults to `inline`" do
        expect(subject.diff_type)
          .to eql "inline"
      end
    end
  end

  describe "reminders" do
    context "without reminders being stored" do
      it "uses the defaults" do
        expect(subject.daily_reminders_enabled).to be(true)
        expect(subject.daily_reminders_times).to eql(["08:00:00+00:00"])
        expect(subject.immediate_reminders_mentioned).to be(true)
        expect(subject.immediate_reminders_personal_reminder).to be(true)
        expect(subject.pause_reminders_enabled).to be(false)
        expect(subject.pause_reminders_first_day).to be_nil
        expect(subject.pause_reminders_last_day).to be_nil
      end
    end

    context "with reminders being stored" do
      let(:preferences) do
        {
          "daily_reminders_enabled" => false,
          "daily_reminders_times" => %w[12:00:00+00:00 18:00:00+00:00 09:00:00+00:00],
          "immediate_reminders_mentioned" => false,
          "pause_reminders_enabled" => true,
          "pause_reminders_first_day" => "2021-10-05",
          "pause_reminders_last_day" => "2021-10-10"
        }
      end

      it "returns the stored values" do
        expect(subject.daily_reminders_enabled).to be(false)
        expect(subject.daily_reminders_times).to eql(%w[12:00:00+00:00 18:00:00+00:00 09:00:00+00:00])
        expect(subject.immediate_reminders_mentioned).to be(false)
        expect(subject.pause_reminders_enabled).to be(true)
        expect(subject.pause_reminders_first_day).to eql(Date.new(2021, 10, 5))
        expect(subject.pause_reminders_last_day).to eql(Date.new(2021, 10, 10))
      end
    end

    describe "#daily_reminders_times=" do
      it "drops blank entries" do
        subject.daily_reminders_times = ["", "09:00:00+00:00", nil]
        expect(subject.daily_reminders_times).to eql(["09:00:00+00:00"])
      end
    end

    describe "#pause_reminders_date_range=" do
      it "splits the range into first and last day" do
        subject.pause_reminders_date_range = "2021-10-05 - 2021-10-10"

        expect(subject.pause_reminders_first_day).to eql(Date.new(2021, 10, 5))
        expect(subject.pause_reminders_last_day).to eql(Date.new(2021, 10, 10))
      end

      it "clears both days for a blank range" do
        subject.pause_reminders_date_range = ""

        expect(subject.pause_reminders_first_day).to be_nil
        expect(subject.pause_reminders_last_day).to be_nil
      end
    end
  end

  describe "#workdays" do
    context "without work days being stored" do
      it "uses the defaults" do
        expect(subject.workdays)
          .to eq([1, 2, 3, 4, 5])
      end
    end

    context "with work days being stored" do
      let(:preferences) do
        {
          "workdays" => [1, 2, 4, 5]
        }
      end

      it "returns the stored value" do
        expect(subject.workdays)
          .to eql([1, 2, 4, 5])
      end
    end

    context "with work days being stored and empty" do
      let(:preferences) do
        {
          "workdays" => []
        }
      end

      it "return empty array" do
        expect(subject.workdays)
          .to eql([])
      end
    end
  end

  describe "persistence" do
    let(:user) { create(:user) }

    it "saves the stored attributes into the settings column" do
      subject.save!

      subject.warn_on_leaving_unsaved = false
      subject.auto_hide_popups = false
      subject.workdays = %w[1 3]

      subject.save!
      subject.reload

      expect(subject.warn_on_leaving_unsaved).to be(false)
      expect(subject.auto_hide_popups).to be(false)
      expect(subject.workdays).to eql([1, 3])
    end

    it "stores structured values as JSON rather than encoded strings" do
      subject.workdays = [1, 3]
      subject.save!

      raw = described_class.where(id: subject.id).pick(Arel.sql("jsonb_typeof(settings->'workdays')"))
      expect(raw).to eq("array")
    end
  end

  describe ".user_settable_preferences" do
    let(:internal_preferences) do
      %w[dismissed_enterprise_banners whats_new_read_items whats_new_seen_version whats_new_seen_at]
    end

    it "contains every stored preference except the internal ones, plus the pause date range" do
      expect(described_class.user_settable_preferences)
        .to match_array(described_class.stored_attributes[:settings] - internal_preferences + %w[pause_reminders_date_range])
    end
  end

  describe "defaults of a new preference" do
    subject(:preference) { described_class.new }

    it "writes the structured defaults into the settings" do
      expect(preference.settings).to include(
        "workdays" => [1, 2, 3, 4, 5],
        "daily_reminders_enabled" => true,
        "daily_reminders_times" => ["08:00:00+00:00"],
        "immediate_reminders_mentioned" => true,
        "immediate_reminders_personal_reminder" => true,
        "pause_reminders_enabled" => false,
        "dismissed_enterprise_banners" => {},
        "whats_new_read_items" => {}
      )
    end
  end

  describe "#time_zone" do
    context "with a time zone set and a default configured", with_settings: { user_default_timezone: "America/Los_Angeles" } do
      let(:preferences) { { "time_zone" => "Africa/Algiers" } }

      it "returns the time zone set" do
        expect(preference.time_zone).to eql "Africa/Algiers"
      end
    end

    context "with no time zone configured but a default", with_settings: { user_default_timezone: "America/Los_Angeles" } do
      it "returns the default time zone" do
        expect(preference.time_zone).to eql "America/Los_Angeles"
      end
    end

    context "with neiter a time zone configured nor a default one", with_settings: { user_default_timezone: "" } do
      it "returns UTC" do
        expect(preference.time_zone).to eql "Etc/UTC"
      end
    end
  end

  describe "#time_zone?" do
    context "with a time zone set and a default configured", with_settings: { user_default_timezone: "America/Los_Angeles" } do
      let(:preferences) { { "time_zone" => "Africa/Algiers" } }

      it "is true" do
        expect(preference).to be_time_zone
      end
    end

    context "with no time zone configured but a default", with_settings: { user_default_timezone: "America/Los_Angeles" } do
      it "is false" do
        expect(preference).not_to be_time_zone
      end
    end

    context "with neiter a time zone configured nor a default one", with_settings: { user_default_timezone: "" } do
      it "is false" do
        expect(preference).not_to be_time_zone
      end
    end
  end

  describe "#date_format" do
    context "with setting set", with_settings: { date_format: "%Y-%m-%d" } do
      context "with preference set" do
        let(:preferences) { { "date_format" => "%Y.%m.%d" } }

        it "returns the preference value" do
          expect(preference.date_format).to eql "%Y.%m.%d"
        end
      end

      context "without preference set" do
        it "returns nil, ignoring the setting" do
          expect(preference.date_format).to be_nil
        end
      end
    end

    context "without default configured" do
      context "with preference set" do
        let(:preferences) { { "date_format" => "%Y.%m.%d" } }

        it "returns the preference value" do
          expect(preference.date_format).to eql "%Y.%m.%d"
        end
      end

      context "without preference set" do
        it "returns empty value" do
          expect(preference.date_format).to be_nil
        end
      end
    end
  end

  describe "#time_format" do
    context "with setting", with_settings: { time_format: "%Hh%M" } do
      context "with preference set" do
        let(:preferences) { { "time_format" => "%H:%M" } }

        it "returns the preference value" do
          expect(preference.time_format).to eql "%H:%M"
        end
      end

      context "without preference set" do
        it "returns nil, ignoring the setting" do
          expect(preference.time_format).to be_nil
        end
      end
    end

    context "without setting" do
      context "with preference set" do
        let(:preferences) { { "time_format" => "%H:%M" } }

        it "returns the preference value" do
          expect(preference.time_format).to eql "%H:%M"
        end
      end

      context "without preference set" do
        it "returns empty value" do
          expect(preference.time_format).to be_nil
        end
      end
    end
  end

  describe "#theme" do
    context "when none is specified" do
      it "defaults to light" do
        expect(subject.theme).to eq("light")
        expect(subject).to be_a_light_theme
        expect(subject).to be_a_light_color_mode
      end
    end

    context "with a dark theme specified" do
      let(:preferences) { { "theme" => "dark" } }

      it "returns the dark theme" do
        expect(subject.theme).to eq("dark")
        expect(subject).to be_a_dark_theme
        expect(subject).to be_a_dark_color_mode
      end
    end

    context "with a light theme and contrast enabled" do
      let(:preferences) { { "theme" => "light", "increase_theme_contrast" => true } }

      it "returns light theme with high contrast detection" do
        expect(subject.theme).to eq("light")
        expect(subject).to be_a_light_theme
        expect(subject).to be_a_light_high_contrast_theme
        expect(subject).to be_a_light_color_mode
        expect(subject.increase_theme_contrast?).to be true
      end
    end

    context "with a dark theme and contrast enabled" do
      let(:preferences) { { "theme" => "dark", "increase_theme_contrast" => true } }

      it "returns dark theme with high contrast detection" do
        expect(subject.theme).to eq("dark")
        expect(subject).to be_a_dark_theme
        expect(subject).to be_a_dark_high_contrast_theme
        expect(subject).to be_a_dark_color_mode
        expect(subject.increase_theme_contrast?).to be true
      end
    end

    context "with light theme and contrast disabled" do
      let(:preferences) { { "theme" => "light", "increase_theme_contrast" => false } }

      it "returns light theme without high contrast" do
        expect(subject.theme).to eq("light")
        expect(subject).to be_a_light_theme
        expect(subject).not_to be_a_light_high_contrast_theme
        expect(subject).to be_a_light_color_mode
        expect(subject.increase_theme_contrast?).to be false
      end
    end

    context "with dark theme and contrast disabled" do
      let(:preferences) { { "theme" => "dark", "increase_theme_contrast" => false } }

      it "returns dark theme without high contrast" do
        expect(subject.theme).to eq("dark")
        expect(subject).to be_a_dark_theme
        expect(subject).not_to be_a_dark_high_contrast_theme
        expect(subject).to be_a_dark_color_mode
        expect(subject.increase_theme_contrast?).to be false
      end
    end

    context "with system theme specified" do
      let(:preferences) { { "theme" => "sync_with_os" } }

      it "returns the system theme" do
        expect(subject.theme).to eq("sync_with_os")
        expect(subject).to be_a_sync_with_os_theme
      end
    end

    context "with unset contrast settings" do
      let(:preferences) { { "theme" => "light" } }

      it "defaults contrast settings to false" do
        expect(subject).not_to be_increase_theme_contrast
        expect(subject).not_to be_force_light_theme_contrast
        expect(subject).not_to be_force_dark_theme_contrast
        expect(subject).not_to be_a_light_high_contrast_theme
        expect(subject).not_to be_a_dark_high_contrast_theme
      end
    end
  end

  describe "#avatar_color=" do
    it "normalizes a long hex form to uppercase" do
      subject.avatar_color = "#aabbcc"
      expect(subject.avatar_color).to eql "#AABBCC"
    end

    it "normalizes a short hex form to its long uppercase form" do
      subject.avatar_color = "#abc"
      expect(subject.avatar_color).to eql "#AABBCC"
    end

    it "clears the value when set to blank" do
      subject.avatar_color = "#aabbcc"
      subject.avatar_color = ""
      expect(subject.avatar_color).to be_nil
    end
  end

  describe "contrast settings" do
    it_behaves_like "accepts real and false booleans",
                    :increase_theme_contrast=,
                    :increase_theme_contrast?

    it_behaves_like "accepts real and false booleans",
                    :force_light_theme_contrast=,
                    :force_light_theme_contrast?

    it_behaves_like "accepts real and false booleans",
                    :force_dark_theme_contrast=,
                    :force_dark_theme_contrast?
  end

  describe "validations" do
    subject(:preference) { build(:user_preference, user:, **attributes) }

    let(:attributes) { {} }

    shared_examples "is valid" do
      it { is_expected.to be_valid }
    end

    shared_examples "is invalid" do |attribute, error|
      it "has a #{error} error on #{attribute}" do
        preference.validate
        expect(preference.errors).to be_of_kind(attribute, error)
      end
    end

    context "without any values" do
      it_behaves_like "is valid"
    end

    context "with an unknown theme" do
      let(:attributes) { { theme: "neon" } }

      it_behaves_like "is invalid", :theme, :inclusion
    end

    context "with an invalid order for comments_sorting" do
      let(:attributes) { { comments_sorting: "up" } }

      it_behaves_like "is invalid", :comments_sorting, :inclusion
    end

    context "with an unknown diff_type" do
      let(:attributes) { { diff_type: "unified" } }

      it_behaves_like "is invalid", :diff_type, :inclusion
    end

    context "with an unknown my_work_view_mode" do
      let(:attributes) { { my_work_view_mode: "board" } }

      it_behaves_like "is invalid", :my_work_view_mode, :inclusion
    end

    context "with an unknown my_work_mode" do
      let(:attributes) { { my_work_mode: "year" } }

      it_behaves_like "is invalid", :my_work_mode, :inclusion
    end

    context "with an unknown avatar_type" do
      let(:attributes) { { avatar_type: "photo" } }

      it_behaves_like "is invalid", :avatar_type, :inclusion
    end

    describe "time_zone" do
      context "with a full time_zone" do
        let(:attributes) { { time_zone: "Europe/Paris" } }

        it_behaves_like "is valid"
      end

      context "without a time_zone but an unassignable default", with_settings: { user_default_timezone: "Nowhere" } do
        it_behaves_like "is valid"
      end

      context "with a non ActiveSupport::Timezone timezone" do
        let(:attributes) { { time_zone: "America/Adak" } }

        it_behaves_like "is invalid", :time_zone, :inclusion
      end

      context "with a malformed time_zone" do
        let(:attributes) { { time_zone: "123Brasilia" } }

        it_behaves_like "is invalid", :time_zone, :inclusion
      end

      context "with a non tzinfo time_zone" do
        let(:attributes) { { time_zone: "Brasilia" } }

        it_behaves_like "is invalid", :time_zone, :inclusion
      end

      context "with an unassignable time_zone that is not being changed" do
        let(:attributes) { { time_zone: "Brasilia" } }

        before { preference.clear_changes_information }

        it_behaves_like "is valid"
      end
    end

    describe "date_format" do
      context "with an allowed date_format" do
        let(:attributes) { { date_format: "%d.%m.%Y" } }

        it_behaves_like "is valid"
      end

      context "with an unallowed date_format" do
        let(:attributes) { { date_format: "%Y foo %m bar %d" } }

        it_behaves_like "is invalid", :date_format, :inclusion
      end

      context "with an unallowed date_format that is not being changed" do
        let(:attributes) { { date_format: "%Y foo %m bar %d" } }

        before { preference.clear_changes_information }

        it_behaves_like "is valid"
      end
    end

    describe "time_format" do
      context "with an allowed time_format" do
        let(:attributes) { { time_format: "%I:%M %p" } }

        it_behaves_like "is valid"
      end

      context "with an unallowed time_format" do
        let(:attributes) { { time_format: "%H foo %M" } }

        it_behaves_like "is invalid", :time_format, :inclusion
      end
    end

    describe "avatar_color" do
      context "with a valid avatar_color" do
        let(:attributes) { { avatar_color: "#AABBCC" } }

        it_behaves_like "is valid"
      end

      context "with an invalid avatar_color" do
        let(:attributes) { { avatar_color: "red" } }

        it_behaves_like "is invalid", :avatar_color, :invalid
      end
    end

    describe "avatar_text" do
      [nil, "", "x", "OP", "山田", "本田", "Жя", "𐐀𐐁", "👩🏽‍💻", "👨‍👩‍👧‍👦", "🇯🇵", "🏳️‍🌈", "❤️", "👍🏽", "1️⃣",
       "éx", "<&", "12", "1#", "🚀🚀", "A🚀", "👨‍👩‍👧‍👦🇯🇵", "🏴󠁧󠁢󠁥󠁮󠁧󠁿", "👩🏽‍❤️‍💋‍👨🏿", "क्षि"].each do |text|
        context "with avatar_text #{text.inspect}" do
          let(:attributes) { { avatar_text: text } }

          it_behaves_like "is valid"
        end
      end

      context "with only surrounding whitespace" do
        let(:attributes) { { avatar_text: "\n " } }

        it "clears the text" do
          expect(preference.avatar_text).to be_nil
          expect(preference).to be_valid
        end
      end

      ["ABC", "本田技", "🚀🚀🚀", "👨‍👩‍👧‍👦🇯🇵a"].each do |text|
        context "with too much avatar text #{text.inspect}" do
          let(:attributes) { { avatar_text: text } }

          it_behaves_like "is invalid", :avatar_text, :too_long
        end
      end

      ["\u0000", "\u0001", "￾", "￿", "​​", "A‮", "á́́́́", 123, ["x"]].each do |text|
        context "with invalid avatar_text #{text.inspect}" do
          let(:attributes) { { avatar_text: text } }

          it "rejects the text" do
            expect(preference).not_to be_valid
            expect(preference.errors[:avatar_text]).to be_present
          end
        end
      end
    end

    describe "workdays" do
      context "with duplicate workday entries" do
        let(:attributes) { { workdays: [1, 1] } }

        it_behaves_like "is invalid", :workdays, :no_duplicates
      end

      context "with non-iso workday entries" do
        let(:attributes) { { workdays: ["foo", 21345, 2] } }

        it_behaves_like "is invalid", :workdays, :inclusion
      end
    end

    describe "daily_reminders_times" do
      context "with full hours" do
        let(:attributes) { { daily_reminders_times: %w[00:00:00+00:00 23:00:00+00:00] } }

        it_behaves_like "is valid"
      end

      context "with an invalid time" do
        let(:attributes) { { daily_reminders_times: %w[abc 12:00:00+00:00] } }

        it_behaves_like "is invalid", :daily_reminders, :full_hour
      end

      context "with an hour outside of the day" do
        let(:attributes) { { daily_reminders_times: %w[25:00:00+00:00] } }

        it_behaves_like "is invalid", :daily_reminders, :full_hour
      end

      context "with a sub hour time" do
        let(:attributes) { { daily_reminders_times: %w[12:30:00+00:00] } }

        it_behaves_like "is invalid", :daily_reminders, :full_hour
      end
    end

    describe "pause reminders" do
      context "with enabled false" do
        let(:attributes) { { pause_reminders_enabled: false } }

        it_behaves_like "is valid"
      end

      context "with enabled true and a valid range" do
        let(:attributes) do
          { pause_reminders_enabled: true, pause_reminders_first_day: "2021-10-05", pause_reminders_last_day: "2021-10-10" }
        end

        it_behaves_like "is valid"
      end

      context "with enabled true but no days" do
        let(:attributes) { { pause_reminders_enabled: true } }

        it_behaves_like "is invalid", :pause_reminders, :blank
      end

      context "with enabled true but only the first day" do
        let(:attributes) { { pause_reminders_enabled: true, pause_reminders_first_day: "2021-10-05" } }

        it_behaves_like "is invalid", :pause_reminders, :blank
      end

      context "with enabled true but only the last day" do
        let(:attributes) { { pause_reminders_enabled: true, pause_reminders_last_day: "2021-10-05" } }

        it_behaves_like "is invalid", :pause_reminders, :blank
      end

      context "with enabled true but an unparseable day" do
        let(:attributes) do
          { pause_reminders_enabled: true, pause_reminders_first_day: "foo", pause_reminders_last_day: "2021-10-05" }
        end

        it_behaves_like "is invalid", :pause_reminders, :blank
      end

      context "with enabled true but the last day before the first day" do
        let(:attributes) do
          { pause_reminders_enabled: true, pause_reminders_first_day: "2021-10-10", pause_reminders_last_day: "2021-10-05" }
        end

        it_behaves_like "is invalid", :pause_reminders, :invalid_range
      end
    end
  end

  describe ".assignable_time_zones" do
    subject(:time_zones) { described_class.assignable_time_zones }

    it "returns a list of AS::TimeZones" do
      expect(time_zones)
        .to(be_all { |tz| tz.is_a?(ActiveSupport::TimeZone) })
    end

    it "includes only the namesake zone if multiple AS::Timezone map to the same TZInfo" do
      # In this case 'Edinburgh' and 'Bern' are not included
      expect(time_zones.select { |tz| %w[Europe/London Europe/Zurich].include? tz.tzinfo.canonical_zone.name })
        .to contain_exactly(ActiveSupport::TimeZone["London"], ActiveSupport::TimeZone["Zurich"])
    end
  end
end
