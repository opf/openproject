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
  let(:view_context) { ApplicationController.new.view_context }

  describe Settings::Pages::Entry do
    describe "#visible?" do
      it "is true without a condition" do
        expect(described_class.new(:app_title)).to be_visible
      end

      it "evaluates the condition" do
        expect(described_class.new(:app_title, if: -> { false })).not_to be_visible
      end
    end

    describe "#label" do
      it "defaults to the setting's translation" do
        expect(described_class.new(:app_title).label(view_context)).to eq I18n.t(:setting_app_title)
      end

      it "translates a given key" do
        expect(described_class.new(:app_title, label: :label_administration).label(view_context))
          .to eq I18n.t(:label_administration)
      end

      it "evaluates a given lambda in the view context" do
        expect(described_class.new(:app_title, label: -> { t(:label_administration) }).label(view_context))
          .to eq I18n.t(:label_administration)
      end
    end

    describe "#caption" do
      it "defaults to the setting's caption translation" do
        expect(described_class.new(:login_required).caption(view_context)).to eq I18n.t(:setting_login_required_caption)
      end

      it "is nil without a caption" do
        expect(described_class.new(:app_title).caption(view_context)).to be_nil
      end
    end
  end

  describe Settings::Pages::Page do
    subject(:settings_page) do
      described_class.new(:spec, menu_item: :settings_general).tap do |page|
        page.instance_exec do
          setting :app_title

          section :welcome, if: -> { false } do
            setting :welcome_title
          end

          setting :feeds_enabled
        end
      end
    end

    it "keeps settings in declaration order, starting a new unnamed section after a named one" do
      expect(settings_page.sections.map(&:key)).to eq [nil, :welcome, nil]
      expect(settings_page.entries.map(&:name)).to eq %i[app_title welcome_title feeds_enabled]
    end

    it "omits the entries of hidden sections" do
      expect(settings_page.sections.flat_map(&:visible_entries).map(&:name)).to eq %i[app_title feeds_enabled]
    end

    it "links to its menu item" do
      expect(settings_page.url).to eq settings_page.menu_node.url
    end

    it "links to its tab of the menu item" do
      tab_page = described_class.new(:spec, menu_item: :settings_general, tab: "spec")

      expect(tab_page.url).to eq settings_page.menu_node.url.merge(tab: "spec")
    end

    it "prefers a given url" do
      url = { controller: "/admin/settings/virus_scanning_settings", action: :show }

      expect(described_class.new(:spec, menu_item: :attachments, url:).url).to eq url
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
  end

  describe "registered pages" do
    it "only list defined settings", :aggregate_failures do
      described_class.all.flat_map(&:entries).each do |entry|
        expect { entry.definition }.not_to raise_error, "for #{entry.name}"
      end
    end

    it "belong to existing admin menu items", :aggregate_failures do
      described_class.all.each do |settings_page|
        expect { settings_page.menu_node }.not_to raise_error, "for #{settings_page.key}"
      end
    end
  end
end
