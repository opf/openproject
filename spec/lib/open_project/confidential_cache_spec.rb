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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe OpenProject::ConfidentialCache do
  let(:cache_key) { SecureRandom.uuid }

  describe "#read and #write" do
    it "roundtrips" do
      expected = "an-expected-value"
      described_class.write(cache_key, expected)
      actual = described_class.read(cache_key)

      expect(actual).to eq(expected)
    end

    it "stores in the same location as OpenProject::Cache" do
      described_class.write(cache_key, "something")

      expect(OpenProject::Cache.read(cache_key)).not_to be_nil
    end

    it "does not store plain text values" do
      plain_text = "an-expected-value"
      described_class.write(cache_key, plain_text)
      stored_text = OpenProject::Cache.read(cache_key)

      expect(stored_text).not_to eq(plain_text)
    end

    it "returns nil when no value has been written" do
      expect(described_class.read(cache_key)).to be_nil
    end

    it "returns nil when the value is undecryptable" do
      OpenProject::Cache.write(cache_key, "some clear text")
      expect(described_class.read(cache_key)).to be_nil
    end
  end

  describe "#fetch" do
    it "returns block results if uncached" do
      values = %w[first second]
      result = described_class.fetch(cache_key) { values.shift }

      expect(result).to eq("first")
    end

    it "returns cached result if cached" do
      values = %w[first second]
      described_class.fetch(cache_key) { values.shift }
      result = described_class.fetch(cache_key) { values.shift }

      expect(result).to eq("first")
    end

    it "returns block results if value is undecryptable" do
      values = %w[first second]
      OpenProject::Cache.write(cache_key, "some clear text")
      result = described_class.fetch(cache_key) { values.shift }

      expect(result).to eq("first")
    end

    it "stores block results in the same location as OpenProject::Cache" do
      values = %w[first second]
      described_class.fetch(cache_key) { values.shift }

      expect(OpenProject::Cache.read(cache_key)).not_to be_nil
    end
  end
end
