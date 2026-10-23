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

RSpec.describe PwaHelper do
  describe "#pwa_cache_name" do
    it "changes when the header colour changes" do
      allow(helper).to receive(:header_bg_color).and_return("#aaaaaa")
      before = helper.pwa_cache_name

      allow(helper).to receive(:header_bg_color).and_return("#123456")

      expect(helper.pwa_cache_name).not_to eq(before)
    end

    it "changes when the dark header colour changes" do
      allow(helper).to receive(:header_bg_color).and_return("#aaaaaa")
      allow(helper).to receive(:header_bg_color).with(color_mode: :dark).and_return("#bbbbbb")
      before = helper.pwa_cache_name

      allow(helper).to receive(:header_bg_color).with(color_mode: :dark).and_return("#123456")

      expect(helper.pwa_cache_name).not_to eq(before)
    end

    it "changes when the app title changes" do
      before = helper.pwa_cache_name

      allow(Setting).to receive(:app_title).and_return("Another title")

      expect(helper.pwa_cache_name).not_to eq(before)
    end

    it "changes when the version changes" do
      before = helper.pwa_cache_name

      stub_const("OpenProject::VERSION", "0.0.1")

      expect(helper.pwa_cache_name).not_to eq(before)
    end

    it "starts with the instance's cache prefix" do
      expect(helper.pwa_cache_name).to start_with(helper.pwa_cache_prefix)
    end
  end

  describe "#pwa_cache_prefix" do
    it "differs between instances served under different paths" do
      allow(helper).to receive(:root_path).and_return("/a/")
      prefix_a = helper.pwa_cache_prefix

      allow(helper).to receive(:root_path).and_return("/b/")

      expect(helper.pwa_cache_prefix).not_to eq(prefix_a)
    end
  end
end
