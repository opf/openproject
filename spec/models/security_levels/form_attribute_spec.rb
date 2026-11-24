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

require "spec_helper"

RSpec.describe "Security level attribute on the work package form" do # rubocop:disable RSpec/DescribeClass
  let(:variant) { create(:type).default_variant }
  let(:details_group) { variant.attribute_groups.find { |group| group.key == :details } }

  it "is offered in projects that use a security level scheme" do
    project = create(:project, security_level_scheme: create(:security_level_scheme))

    expect(variant.passes_attribute_constraint?(:security_level, project:)).to be true
    expect(details_group.active_members(project)).to include("security_level")
  end

  it "is hidden in projects without a scheme" do
    project = create(:project)

    expect(variant.passes_attribute_constraint?(:security_level, project:)).to be false
    expect(details_group.active_members(project)).not_to include("security_level")
  end

  it "is available when configuring a type outside of a project" do
    expect(variant.passes_attribute_constraint?(:security_level, project: nil)).to be true
  end
end
