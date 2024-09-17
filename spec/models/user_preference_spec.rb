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

RSpec.describe UserPreference do
  subject(:preference) do
    build(:user_preference,
          user:,
          settings:)
  end

  let(:settings) { {} }

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

  describe "hide_mail" do
    it_behaves_like "accepts real and false booleans",
                    :hide_mail=,
                    :hide_mail?

    context "when a new pref instance" do
      subject { described_class.new }

      it "defaults to true" do
        expect(subject.settings[:hide_mail]).to be_nil
        expect(subject.hide_mail).to be true
        expect(subject.hide_mail?).to be true

        subject.hide_mail = false
        expect(subject.settings[:hide_mail]).to be false
        expect(subject.hide_mail).to be false
        expect(subject.hide_mail?).to be false
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

  describe "#daily_reminders" do
    context "without reminders being stored" do
      it "uses the defaults" do
        expect(subject.daily_reminders)
          .to eql("enabled" => true, "times" => ["08:00:00+00:00"])
      end
    end

    context "with reminders being stored" do
      let(:settings) do
        {
          "daily_reminders" => {
            "enabled" => false,
            "times" => %w[12:00:00+00:00 18:00:00+00:00 09:00:00+00:00]
          }
        }
      end

      it "returns the stored value" do
        expect(subject.daily_reminders)
          .to eql(settings["daily_reminders"])
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
      let(:settings) do
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
      let(:settings) do
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

  describe "[]=" do
    let(:user) { create(:user) }

    it 'saves the values on sending "save"' do
      subject.save

      value_warn_on_leaving_unsaved = !subject[:warn_on_leaving_unsaved]
      value_auto_hide_popups = !subject[:auto_hide_popups]

      subject[:warn_on_leaving_unsaved] = value_warn_on_leaving_unsaved
      subject[:auto_hide_popups] = value_auto_hide_popups

      subject.save
      subject.reload

      expect(subject[:warn_on_leaving_unsaved]).to eql(value_warn_on_leaving_unsaved)
      expect(subject[:auto_hide_popups]).to eql(value_auto_hide_popups)
    end
  end
end
