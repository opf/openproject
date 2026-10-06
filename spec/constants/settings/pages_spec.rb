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

require "spec_helper"

RSpec.describe Settings::Pages do
  describe Settings::Pages::Entry do
    describe "#input" do
      {
        feeds_enabled: :check_box,
        feeds_limit: :number_field,
        app_title: :text_field,
        antivirus_scan_action: :radio_button_group,
        default_language: :select_list,
        working_days: :check_box_group,
        allowed_link_protocols: :text_area
      }.each do |name, input|
        it "derives #{input} for #{name}" do
          expect(described_class.new(name).input).to eq input
        end
      end

      it "prefers an input given in the definition's ui hints" do
        expect(described_class.new(:welcome_text).input).to eq :rich_text_area
      end

      it "prefers an input given on the page over the definition's ui hints" do
        expect(described_class.new(:welcome_text, input: :text_area).input).to eq :text_area
      end

      it "fails for formats it cannot derive an input for" do
        expect { described_class.new(:fog).input }.to raise_error(ArgumentError, /fog/)
      end
    end

    describe "#input_options" do
      it "merges the page hints over the definition's ui hints, dropping its own hints" do
        entry = described_class.new(:activity_days_default, input_width: :xsmall)

        expect(entry.input_options).to eq(input_width: :xsmall)
        expect(entry.ui).to include(unit: :label_day_plural, input_width: :xsmall)
      end
    end

    describe "#visible?" do
      it "is true without a condition" do
        expect(described_class.new(:app_title)).to be_visible
      end

      it "evaluates the condition" do
        expect(described_class.new(:app_title, if: -> { false })).not_to be_visible
      end
    end

    describe "#permit_filter" do
      it "permits an array for check box groups" do
        expect(described_class.new(:working_days).permit_filter).to eq(working_days: [])
      end

      it "permits a scalar for arrays entered as text" do
        expect(described_class.new(:allowed_link_protocols).permit_filter).to eq :allowed_link_protocols
      end
    end

    describe "#parse_param" do
      it "splits arrays entered as text into lines and applies the parse hint" do
        expect(described_class.new(:allowed_link_protocols).parse_param("FTP\r\n\r\ns ftp \n"))
          .to eq %w[ftp sftp]
      end

      it "keeps other values" do
        expect(described_class.new(:app_title).parse_param("Title")).to eq "Title"
      end
    end
  end

  describe Settings::Pages::Page do
    subject(:settings_page) do
      described_class.new(:spec, menu_item: :settings_general).tap do |page|
        page.instance_exec do
          setting :app_title

          section :welcome do
            setting :welcome_title
          end

          setting :feeds_enabled
        end
      end
    end

    it "keeps settings in declaration order, starting a new untitled section after a titled one" do
      expect(settings_page.sections.map(&:key)).to eq [nil, :welcome, nil]
      expect(settings_page.entries.map(&:name)).to eq %i[app_title welcome_title feeds_enabled]
    end

    it "derives the section heading from its key" do
      expect(settings_page.sections.second.heading).to eq :setting_welcome
    end

    it "finds entries by name" do
      expect(settings_page.entry("welcome_title").name).to eq :welcome_title
    end

    it "resolves its menu node and ancestors from the admin menu" do
      expect(settings_page.menu_node.name).to eq :settings_general
      expect(settings_page.menu_ancestors.map(&:name)).to eq [:settings]
    end
  end

  describe "registry" do
    before do
      allow(described_class).to receive(:registry).and_return({})
    end

    it "registers pages and allows extending them" do
      described_class.draw do
        page :spec, menu_item: :settings_general do
          setting :app_title
        end
      end

      described_class.extend_page(:spec) do
        setting :feeds_enabled
      end

      expect(described_class.fetch(:spec).entries.map(&:name)).to eq %i[app_title feeds_enabled]
    end

    it "refuses to register a page twice" do
      described_class.page(:spec, menu_item: :settings_general)

      expect { described_class.page(:spec, menu_item: :settings_general) }.to raise_error(ArgumentError)
    end

    it "lists custom pages separately" do
      described_class.page(:spec, menu_item: :settings_general)
      described_class.page(:custom_spec, menu_item: :settings_general, custom: true)

      expect(described_class.auto_rendered.map(&:key)).to eq [:spec]
    end
  end

  describe "core pages" do
    it "only lists settings with a derivable input on auto-rendered pages", :aggregate_failures do
      described_class.auto_rendered.flat_map(&:entries).each do |entry|
        expect { entry.input }.not_to raise_error, "for #{entry.name}"
      end
    end
  end
end
