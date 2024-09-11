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

RSpec.describe JournalFormatterCache do
  subject(:cache) { described_class.new }

  describe "#fetch" do
    it "caches and returns the value returned by the block on cache miss" do
      expect(cache.fetch(User, 3) { "user_3" }).to eq("user_3")
      expect(cache.fetch("Answer", 42) { "Life Universe Everything" }).to eq("Life Universe Everything")
    end

    it "returns nil on cache miss if no block is given" do
      expect(cache.fetch(User, 3)).to be_nil
      expect(cache.fetch(User, 17)).to be_nil
    end

    it "returns the cached value on cache hit" do
      cache.fetch(User, 3) { "user_3" }

      expect(cache.fetch(User, 3)).to eq("user_3")
      expect(cache.fetch(User, 3) { "another value" }).to eq("user_3")

      expect(cache.fetch(Project, 62)).to be_nil
      cache.fetch(Project, 62) { "project_62" }
      expect(cache.fetch(Project, 62)).to eq("project_62")
      cache.fetch(Project, 62) { "another value" }
      expect(cache.fetch(Project, 62)).to eq("project_62")
    end
  end
end
