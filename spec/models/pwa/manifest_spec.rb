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

RSpec.describe Pwa::Manifest do
  subject(:manifest) { described_class.new(ApplicationController.helpers).as_json }

  describe "short_name" do
    it "keeps a title that fits under an icon", with_settings: { app_title: "OpenProject" } do
      expect(manifest[:short_name]).to eq("OpenProject")
    end

    it "omits a longer title rather than guessing a word from it", with_settings: { app_title: "My Company Projects" } do
      expect(manifest).not_to have_key(:short_name)
    end

    it "omits a blank title", with_settings: { app_title: " " } do
      expect(manifest).not_to have_key(:short_name)
    end
  end
end
