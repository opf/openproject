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

require "rails_helper"

RSpec.describe OpenProject::Internationalization::JsDateTimeFormat do
  describe ".date" do
    it "translates known specifiers" do
      expect(described_class.date("%Y-%y-%m-%B-%b-%h-%d-%e-%j")).to eq("YYYY-YY-MM-MMMM-MMM-MMM-DD-D-DDDD")
    end

    it "drops unknown specifiers" do
      expect(described_class.date("%Y-%X-%m")).to eq("YYYY--MM")
    end

    it "returns nil for blank input" do
      expect(described_class.date(nil)).to be_nil
      expect(described_class.date("")).to be_nil
      expect(described_class.date("%X")).to be_nil
    end
  end

  describe ".time" do
    it "translates known specifiers" do
      expect(described_class.time("%H-%k-%I-%l-%P-%p-%M")).to eq("HH-H-hh-h-a-A-mm")
    end

    it "drops unknown specifiers" do
      expect(described_class.time("%H-%X-%M")).to eq("HH--mm")
    end

    it "returns nil for blank input" do
      expect(described_class.time(nil)).to be_nil
      expect(described_class.time("")).to be_nil
      expect(described_class.time("%X")).to be_nil
    end
  end
end
