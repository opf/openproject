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

RSpec.describe Queries::Users::Selects::Department do
  describe ".key" do
    it "is :department" do
      expect(described_class.key).to eq(:department)
    end
  end

  describe "#caption" do
    it "is the user attribute name" do
      expect(described_class.new(:department).caption).to eq(User.human_attribute_name(:department))
    end
  end

  describe "selecting it on a UserQuery" do
    shared_let(:user) { create(:user) }
    shared_let(:department) { create(:department, members: [user]) }

    let(:query) { UserQuery.new(name: "Users") }

    current_user { create(:admin) }

    it "is available" do
      expect(UserQuery.new.available_selects).to include(an_instance_of(described_class))
    end

    it "resolves to the select" do
      query.select(:department)

      expect(query.selects.last).to be_a(described_class)
    end

    it "eager loads the departments" do
      query.select(:department)

      expect(query.results.to_a.map { it.association(:departments) }).to all(be_loaded)
    end

    it "does not eager load them when not selected" do
      associations = query.results.to_a.map { it.association(:departments) }

      expect(associations).to be_present
      expect(associations.none?(&:loaded?)).to be(true)
    end
  end
end
