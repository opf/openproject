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

RSpec.describe PwaHelper do
  describe "#pwa_short_name" do
    it "keeps a title that fits under an icon" do
      expect(helper.pwa_short_name("OpenProject")).to eq("OpenProject")
    end

    it "falls back to the first word of a longer title" do
      expect(helper.pwa_short_name("Acme Projektverwaltung")).to eq("Acme")
    end

    it "gives none rather than cutting a long single word" do
      expect(helper.pwa_short_name("Projektverwaltungssystem")).to be_nil
    end

    it "gives none for a long blank title" do
      expect(helper.pwa_short_name(" " * 13)).to be_nil
    end
  end

  describe "shell caching" do
    let(:entry_files) { %w[/assets/frontend/polyfills-abc.js /assets/frontend/main-abc.js /assets/frontend/styles-abc.css] }

    before do
      allow(FrontendAssetHelper).to receive(:assets_proxied?).and_return(false)
      allow(helper).to receive(:raw_variable_asset_path) do |file|
        entry_files.find { |path| path.include?(file.split(".").first) }
      end
    end

    describe "#pwa_shell_precache" do
      it "lists the entry files and the icons as same-origin paths" do
        expect(helper.pwa_shell_precache).to include(*entry_files)
        expect(helper.pwa_shell_precache).to include(helper.image_path("pwa/icon-192.png"), helper.image_path("pwa/icon.svg"))
      end

      it "leaves out urls on another origin" do
        allow(helper).to receive(:image_path).and_call_original
        allow(helper).to receive(:image_path).with("pwa/icon-512.png").and_return("https://cdn.example.com/icon-512.png")
        allow(helper).to receive(:image_path).with("pwa/icon-1024.png").and_return("//cdn.example.com/icon-1024.png")

        expect(helper.pwa_shell_precache).to all(start_with("/"))
        expect(helper.pwa_shell_precache.grep(/cdn\.example/)).to be_empty
      end

      it "is empty while the dev proxy serves the assets" do
        allow(FrontendAssetHelper).to receive(:assets_proxied?).and_return(true)

        expect(helper.pwa_shell_precache).to be_empty
      end
    end

    describe "#pwa_shell_cache_name" do
      it "is prefixed with a short digest" do
        expect(helper.pwa_shell_cache_name).to match(/\Aopenproject-shell-\h{16}\z/)
      end

      it "changes when the custom style changes" do
        before_name = helper.pwa_shell_cache_name
        allow(CustomStyle).to receive(:current).and_return(instance_double(CustomStyle, digest: "other"))

        expect(helper.pwa_shell_cache_name).not_to eq(before_name)
      end
    end
  end
end
