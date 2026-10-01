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

RSpec.describe WorkPackages::ActivitiesTab::Filters do
  describe ".cast" do
    it "returns a known mode given as a symbol unchanged" do
      expect(described_class.cast(:only_comments)).to eq(:only_comments)
    end

    it "coerces a known mode given as a string to its symbol" do
      expect(described_class.cast("only_changes")).to eq(:only_changes)
    end

    it "falls back to ALL for an unknown value" do
      expect(described_class.cast("bogus")).to eq(described_class::ALL)
    end

    it "falls back to ALL for a blank string" do
      expect(described_class.cast("")).to eq(described_class::ALL)
    end

    it "falls back to ALL for nil" do
      expect(described_class.cast(nil)).to eq(described_class::ALL)
    end
  end
end
