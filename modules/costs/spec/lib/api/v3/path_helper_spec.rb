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

RSpec.describe API::V3::Utilities::PathHelper do
  let(:helper) { Class.new.tap { |c| c.extend(described_class) }.api_v3_paths }

  describe "#cost_entry" do
    subject { helper.cost_entry 42 }

    it { is_expected.to eql("/api/v3/cost_entries/42") }
  end

  describe "#cost_entries_by_work_package" do
    subject { helper.cost_entries_by_work_package 42 }

    it { is_expected.to eql("/api/v3/work_packages/42/cost_entries") }
  end

  describe "#summarized_work_package_costs_by_type" do
    subject { helper.summarized_work_package_costs_by_type 42 }

    it { is_expected.to eql("/api/v3/work_packages/42/summarized_costs_by_type") }
  end

  describe "#cost_type" do
    subject { helper.cost_type 42 }

    it { is_expected.to eql("/api/v3/cost_types/42") }
  end
end
