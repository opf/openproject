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

# Timestamp strings that span multiple lines must be rejected at every entry point.
# The date-keyword regex previously used ^ and $ (line anchors), which caused it to
# match only the first line of a multi-line string. The remaining lines were silently
# kept in the stored string and later interpolated verbatim into SQL.
RSpec.describe Timestamp do
  let(:valid_keyword) { "oneDayAgo@00:00+00:00" }
  let(:multiline_input) { "#{valid_keyword}\n@' extra_content" }

  describe ".parse" do
    it "accepts a single-line date-keyword timestamp" do
      expect { described_class.parse(valid_keyword) }.not_to raise_error
    end

    it "rejects a multi-line string whose first line is a valid date keyword" do
      expect { described_class.parse(multiline_input) }.to raise_error(ArgumentError)
    end

    it "rejects a multi-line string whose first line is a valid ISO 8601 datetime" do
      expect { described_class.parse("2024-01-01T00:00:00Z\nextra_content") }.to raise_error(ArgumentError)
    end
  end

  describe "#valid?" do
    it "returns true for a single-line date-keyword timestamp" do
      expect(described_class.new(valid_keyword)).to be_valid
    end

    it "returns false for a multi-line string whose first line is a valid date keyword" do
      expect(described_class.new(multiline_input)).not_to be_valid
    end
  end
end
