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

module OpenProject
  RSpec.describe I18n, type: :helper do
    include Redmine::I18n

    let(:format) { "%d/%m/%Y" }
    let(:user) { build_stubbed(:user) }

    after do
      Time.zone = nil
    end

    describe "with user time zone" do
      before do
        login_as user
        allow(user).to receive(:time_zone).and_return(ActiveSupport::TimeZone["Athens"])
      end

      it "returns a date in the user timezone for a utc timestamp" do
        Time.zone = "UTC"
        time = Time.zone.local(2013, 6, 30, 23, 59)
        expect(format_time_as_date(time, format)).to eq "01/07/2013"
      end

      it "returns a date in the user timezone for a non-utc timestamp" do
        Time.zone = "Berlin"
        time = Time.zone.local(2013, 6, 30, 23, 59)
        expect(format_time_as_date(time, format)).to eq "01/07/2013"
      end
    end

    describe "without user time zone" do
      before { allow(User.current).to receive(:time_zone).and_return(nil) }

      it "returns a date in the local system timezone for a utc timestamp" do
        Time.zone = "UTC"
        time = Time.zone.local(2013, 6, 30, 23, 59)
        allow(time).to receive(:localtime).and_return(ActiveSupport::TimeZone["Athens"].local(2013, 7, 1, 1, 59))
        expect(format_time_as_date(time, format)).to eq "01/07/2013"
      end

      it "returns a date in the original timezone for a non-utc timestamp" do
        Time.zone = "Berlin"
        time = Time.zone.local(2013, 6, 30, 23, 59)
        expect(format_time_as_date(time, format)).to eq "30/06/2013"
      end
    end

    describe "all_languages" do
      # Those are the two languages we support
      it "includes en" do
        expect(all_languages).to include("en")
      end

      it "includes de" do
        expect(all_languages).to include("de")
      end

      it "returns no js language as they are duplicates of the rest of the other language" do
        expect(all_languages).not_to(be_any { |l| l.to_s.start_with?("js-") })
      end

      # it is OK if more languages exist
      it "has multiple languages" do
        expect(all_languages).to include "en", "de", "fr", "es"
        expect(all_languages.size).to be >= 25
      end
    end

    describe "valid_languages" do
      it "allows languages that are available" do
        with_settings(available_languages: ["en"])

        expect(valid_languages).to eq ["en"]
      end

      it "allows language which is not in available languages list but is the default language" do
        with_settings(available_languages: ["en"], default_language: "fr")

        expect(valid_languages).to eq ["en", "fr"]
      end

      it "allows only languages that exist" do
        with_settings(available_languages: ["en", "de", "klingon"])

        expect(valid_languages).to contain_exactly("en", "de")
      end

      it "is sorted alphabetically" do
        with_settings(available_languages: ["de", "en"], default_language: "fr")
        expect(valid_languages).to eq(valid_languages.sort)

        with_settings(available_languages: ["en", "fr"], default_language: "de")
        expect(valid_languages).to eq(valid_languages.sort)
      end
    end

    describe "set_language_if_valid" do
      before do
        allow(described_class).to receive(:locale=)
      end

      context "with all supported languages available" do
        before do
          with_settings(available_languages: Redmine::I18n.all_languages)
        end

        Setting.all_languages.each do |lang|
          it "sets I18n.locale to #{lang.inspect}" do
            set_language_if_valid(lang.to_s)
            set_language_if_valid(lang.to_sym)
            expect(described_class).to have_received(:locale=).with(lang.to_s).twice
          end
        end
      end

      it "does not set I18n.locale to an unavailable language" do
        with_settings(available_languages: ["en"])

        set_language_if_valid("de")
        set_language_if_valid(:de)
        expect(described_class).not_to have_received(:locale=).with(:de)
        expect(described_class).not_to have_received(:locale=).with("de")
      end
    end

    describe "find_language" do
      before do
        with_settings(available_languages: ["de"], default_language: "en")
      end

      it "is nil if language is not available nor the default language" do
        expect(find_language(:fr)).to be_nil
      end

      it "is nil if no language is given" do
        expect(find_language("")).to be_nil
        expect(find_language(nil)).to be_nil
      end

      it "is the language if it is in available languages" do
        expect(find_language(:de)).to eq "de"
        expect(find_language("de")).to eq "de"
      end

      it "is the language if it is the default language" do
        expect(find_language(:en)).to eq "en"
        expect(find_language("en")).to eq "en"
      end

      it "can be found by uppercase" do
        expect(find_language(:DE)).to eq "de"
        expect(find_language("DE")).to eq "de"
        expect(find_language(:EN)).to eq "en"
        expect(find_language("EN")).to eq "en"
      end

      it "is nil if non valid string is passed" do
        expect(find_language("*")).to be_nil
        expect(find_language("78445")).to be_nil
        expect(find_language("/)(")).to be_nil
      end
    end

    describe "link_translation" do
      let(:locale) { :en }
      let(:urls) do
        { url_1: "http://openproject.com/foobar", url_2: "/baz" }
      end

      before do
        allow(::I18n)
          .to receive(:t)
          .with("translation_with_a_link", locale:)
          .and_return("There is a [link](url_1) in this translation! Maybe even [two](url_2)?")
      end

      it "allows to insert links into translations" do
        translated = link_translate :translation_with_a_link, links: urls

        expect(translated).to eq(
          "There is a <a href=\"http://openproject.com/foobar\">link</a> in this translation!" +
          " Maybe even <a href=\"/baz\">two</a>?"
        )
      end

      context "with locale" do
        let(:locale) { :de }

        it "uses the passed locale" do
          translated = link_translate(:translation_with_a_link, links: urls, locale:)

          expect(translated).to eq(
            "There is a <a href=\"http://openproject.com/foobar\">link</a> in this translation!" +
            " Maybe even <a href=\"/baz\">two</a>?"
          )
        end
      end
    end

    describe "#format_date" do
      context "without a date_format setting", with_settings: { date_format: "" } do
        it "uses the locale formate" do
          expect(format_date(Date.today))
            .to eql described_class.l(Date.today)
        end
      end

      context "with a date_format setting", with_settings: { date_format: "%d %m %Y" } do
        it "adheres to the format" do
          expect(format_date(Date.today))
            .to eql Date.today.strftime("%d %m %Y")
        end
      end

      valid_languages.each do |lang|
        context "for lang #{lang}" do
          it "raises no error" do
            described_class.with_locale lang do
              expect { format_date(Date.today) }
                .not_to raise_error
            end
          end
        end
      end
    end

    describe "#numer_to_human_size" do
      valid_languages.each do |lang|
        context "for locale #{lang}" do
          it "does not raise an error" do
            described_class.with_locale lang do
              expect { number_to_human_size(1024 * 1024 * 4) }
                .not_to raise_error
            end
          end
        end
      end
    end

    describe "#format_time", with_settings: {
      time_format: "%H %M",
      date_format: "%d %m %Y"
    } do
      let!(:now) { Time.parse("2011-02-20 15:45:22") }

      it "with date and hours" do
        expect(format_time(now))
          .to eql now.strftime("%d %m %Y %H %M")
      end

      it "with only hours" do
        expect(format_time(now, false))
          .to eql now.strftime("%H %M")
      end

      it "with a utc to date and hours" do
        expect(format_time(now.utc))
          .to eql now.localtime.strftime("%d %m %Y %H %M")
      end

      it "with a utce to only hours" do
        expect(format_time(now.utc, false))
          .to eql now.localtime.strftime("%H %M")
      end

      context "with a different format defined", with_settings: {
        time_format: "%H:%M",
        date_format: "%Y-%m-%d"
      } do
        it "renders date and hours" do
          expect(format_time(now))
            .to eql "2011-02-20 15:45"
        end

        it "renders only hours" do
          expect(format_time(now, false))
            .to eql "15:45"
        end
      end

      context "without time and date format", with_settings: {
        time_format: "",
        date_format: ""
      } do
        it "falls back to default for date and hours" do
          expect(format_time(now))
            .to eql "02/20/2011 03:45 PM"
        end

        it "falls back to default for only hours" do
          expect(format_time(now, false))
            .to eql "03:45 PM"
        end

        valid_languages.each do |lang|
          context "for lang #{lang}" do
            it "raises no error for date and hours" do
              described_class.with_locale lang do
                expect { format_time(now) }
                  .not_to raise_error
              end
            end

            it "raises no error for only hours" do
              described_class.with_locale lang do
                expect { format_time(now, false) }
                  .not_to raise_error
              end
            end
          end
        end
      end

      context "without time format", with_settings: {
        time_format: "",
        date_format: "%Y-%m-%d"
      } do
        it "falls back to default for date and hours" do
          expect(format_time(now))
            .to eql "2011-02-20 03:45 PM"
        end

        it "falls back to default for only hours" do
          expect(format_time(now, false))
            .to eql "03:45 PM"
        end
      end

      context "without date format", with_settings: {
        time_format: "%H:%M",
        date_format: ""
      } do
        it "falls back to default for date and hours" do
          expect(format_time(now))
            .to eql "02/20/2011 15:45"
        end

        it "falls back to default for only hours" do
          expect(format_time(now, false))
            .to eql "15:45"
        end
      end
    end

    describe "day names" do
      valid_languages.each do |lang|
        context "for locale #{lang}" do
          it "is an array" do
            described_class.with_locale lang do
              expect(described_class.t("date.day_names"))
                .to be_a Array
            end
          end

          it "has 7 elements" do
            described_class.with_locale lang do
              expect(described_class.t("date.day_names").size)
                .to eq 7
            end
          end
        end
      end
    end

    describe "month names" do
      valid_languages.each do |lang|
        context "for locale #{lang}" do
          it "is an array" do
            described_class.with_locale lang do
              expect(described_class.t("date.month_names"))
                .to be_a Array
            end
          end

          it "has 13 elements" do
            described_class.with_locale lang do
              expect(described_class.t("date.month_names").size)
                .to eq 13
            end
          end
        end
      end
    end

    describe ".l" do
      valid_languages.each do |lang|
        context "for locale #{lang}" do
          it "is not 'default' for a date" do
            described_class.with_locale lang do
              expect(described_class.l(Date.today, format: :default))
                .not_to eq "default"
            end
          end

          it "is not 'default' for a time" do
            described_class.with_locale lang do
              expect(described_class.l(Time.zone.now, format: :default))
                .not_to eq "time"
            end
          end
        end
      end
    end
  end
end
