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

RSpec.describe API::Bim::Utilities::PathHelper::BCF2_1Path do # rubocop:disable RSpec/SpecFilePathFormat
  before do
    allow(described_class)
      .to receive(:root_path)
      .and_return("/openproject/")
  end

  describe ".project" do
    it "escapes slash characters in project identifiers" do
      expect(described_class.project("project/with/path"))
        .to eq("/openproject/api/bcf/2.1/projects/project%2Fwith%2Fpath")
    end
  end

  describe ".topic" do
    it "escapes topic UUIDs so they stay a single path segment" do
      expect(described_class.topic("my/project", "topic/with/path"))
        .to eq("/openproject/api/bcf/2.1/projects/my%2Fproject/topics/topic%2Fwith%2Fpath")
    end
  end
end
