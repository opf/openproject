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
require "open_project/passwords"

RSpec.describe OpenProject::Passwords::Generator do
  describe "#random_password",
           with_settings: {
             password_active_rules: %w(lowercase uppercase numeric special),
             password_min_length: 4
           } do
    it "creates a valid password" do
      pwd = described_class.random_password
      expect(OpenProject::Passwords::Evaluator.conforming?(pwd)).to be(true)
    end
  end
end

RSpec.describe OpenProject::Passwords::Evaluator,
               with_settings: {
                 password_active_rules: %w(lowercase uppercase numeric),
                 password_min_length: 4
               } do
  it "requires all active rules to be met" do
    # Missing numeric
    expect(described_class.conforming?("abCD")).to be(false)
    # Missing uppercase
    expect(described_class.conforming?("ab12")).to be(false)
    # Missing lowercase
    expect(described_class.conforming?("12CD")).to be(false)
    # Has special but missing lowercase
    expect(described_class.conforming?("12CD*")).to be(false)
    # Too short
    expect(described_class.conforming?("aB1")).to be(false)
    # All 3 active rules met
    expect(described_class.conforming?("abCD12")).to be(true)
    expect(described_class.conforming?("aB123")).to be(true)
  end
end
