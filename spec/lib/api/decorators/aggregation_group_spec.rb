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

RSpec.describe API::Decorators::AggregationGroup do
  include API::V3::Utilities::PathHelper

  let(:query) do
    query = build_stubbed(:query)
    query.group_by = :assigned_to

    query
  end
  let(:group_key) { OpenStruct.new name: "ABC" }
  let(:count) { 5 }
  let(:current_user) { build_stubbed(:user) }

  subject { described_class.new(group_key, count, query:, current_user:).to_json }

  context "with an empty array key" do
    let(:group_key) { [] }

    it "has an empty value" do
      expect(subject)
        .to be_json_eql(nil.to_json)
        .at_path("value")
    end

    it "has no valueLink" do
      expect(subject)
        .to be_json_eql([].to_json)
        .at_path("_links/valueLink")
    end
  end

  context "with an array key (e.g. grouping by a collection association)" do
    let(:version_one) { build_stubbed(:version, name: "1.0") }
    let(:version_two) { build_stubbed(:version, name: "2.0") }
    let(:group_key) { [version_one, version_two] }

    it "joins the elements sorted by their string representation" do
      expect(subject)
        .to be_json_eql("#{version_one.name}, #{version_two.name}".to_json)
        .at_path("value")
    end

    it "links to each element with its title" do
      expected = [
        { href: api_v3_paths.version(version_one.id), title: version_one.name },
        { href: api_v3_paths.version(version_two.id), title: version_two.name }
      ]

      expect(subject)
        .to be_json_eql(expected.to_json)
        .at_path("_links/valueLink")
    end
  end
end
