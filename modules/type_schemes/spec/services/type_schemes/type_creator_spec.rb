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

# frozen_string_literal: true

require "spec_helper"

RSpec.describe TypeSchemes::TypeCreator do
  let(:admin) { create(:admin) }

  before { User.current = admin }
  after { User.current = nil }

  describe ".call" do
    it "creates the requested types" do
      result = described_class.call(%w[Sub-Tasks Spike])

      expect(result).to be_success
      expect(result.result.map(&:name)).to eq(%w[Sub-Tasks Spike])
      expect(Type.where(name: %w[Sub-Tasks Spike]).count).to eq(2)
    end

    it "reuses an existing type case-insensitively and drops blanks" do
      existing = create(:type, name: "Sub-Tasks")

      result = described_class.call(["sub-tasks", "SUB-TASKS", " "])

      expect(result).to be_success
      expect(result.result).to eq([existing])
      expect(Type.where("LOWER(name) = ?", "sub-tasks").count).to eq(1)
    end

    it "returns an empty list for blank input" do
      result = described_class.call([" ", ""])

      expect(result).to be_success
      expect(result.result).to be_empty
    end

    it "fails when a type cannot be created" do
      result = described_class.call(["x" * 256])

      expect(result).to be_failure
      expect(result.errors).not_to be_empty
      expect(Type.where("LENGTH(name) > 255")).to be_empty
    end

    it "rejects too many names at once" do
      result = described_class.call(Array.new(described_class::MAX_NAMES + 1) { |i| "Type #{i}" })

      expect(result).to be_failure
      expect(result.errors.full_messages.join).to include("at most")
    end

    it "stops at the first failure without creating the remaining types" do
      result = described_class.call(["x" * 256, "ShouldNotExist"])

      expect(result).to be_failure
      expect(Type.exists?(name: "ShouldNotExist")).to be(false)
    end
  end
end
