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

RSpec.describe TypeVariant, "allocated time attribute" do
  let(:type_variant) { build_stubbed(:type_variant) }

  it "places the allocated time in the estimates and progress group by default" do
    estimates_group = type_variant.default_attribute_groups.to_h[:estimates_and_progress]

    expect(estimates_group).to include("allocated_time")
  end

  describe "#passes_attribute_constraint?" do
    it "is available in projects with resource management" do
      project = build_stubbed(:project, enabled_module_names: %w[resource_management])

      expect(type_variant.passes_attribute_constraint?(:allocated_time, project:)).to be(true)
    end

    it "is unavailable in projects without resource management" do
      project = build_stubbed(:project, enabled_module_names: %w[work_package_tracking])

      expect(type_variant.passes_attribute_constraint?(:allocated_time, project:)).to be(false)
    end

    it "is available without a project context" do
      expect(type_variant.passes_attribute_constraint?(:allocated_time)).to be(true)
    end
  end
end
