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

RSpec.describe Queries::Projects::Filters::TypeVariantFilter do
  it_behaves_like "basic query filter" do
    let(:class_key) { :type_variant_id }
    let(:type) { :list }
    let(:model) { Project }
    let(:attribute) { :type_variant_id }
    let(:values) { ["3"] }
  end

  def filter(operator, values)
    described_class.create!(operator:, values:)
  end

  describe "#allowed_values" do
    let!(:bug) { create(:type, name: "Bug") }
    let!(:hardware) { create(:type_variant, type: bug, variant_name: "Hardware") }
    let!(:task) { create(:type, name: "Task") }

    it "lists the variants by composite name, base variant first within each type" do
      expect(filter("=", []).allowed_values)
        .to eq [["Bug", bug.default_variant.id],
                ["Bug: Hardware", hardware.id],
                ["Task", task.default_variant.id]]
    end
  end

  describe "#apply_to" do
    let(:bug) { create(:type) }
    let(:task) { create(:type) }
    let(:hardware) { create(:type_variant, type: bug) }
    let(:software) { create(:type_variant, type: bug) }
    let(:recurring) { create(:type_variant, type: task) }

    let!(:hardware_project) { create(:project, types: [hardware]) }
    let!(:software_project) { create(:project, types: [software]) }
    let!(:both_project) { create(:project, types: [hardware, recurring]) }
    let!(:base_project) { create(:project, types: [bug]) }
    let!(:other_project) { create(:project, types: [task]) }

    let(:values) { [hardware.id.to_s, software.id.to_s, recurring.id.to_s] }

    context 'for "="' do
      it "returns every project the variants are enabled in, without duplicating those enabling several" do
        expect(filter("=", values).apply_to(Project))
          .to contain_exactly(hardware_project, software_project, both_project)
      end
    end

    context "with the base variant of a type" do
      it "matches only the projects that enabled it" do
        expect(filter("=", [bug.default_variant.id.to_s]).apply_to(Project))
          .to contain_exactly(base_project)
      end

      it "leaves out a project that never enabled the type" do
        never_enabled = create(:project, types: [])

        expect(filter("=", [bug.default_variant.id.to_s]).apply_to(Project))
          .not_to include(never_enabled)
      end
    end

    context 'for "!"' do
      it "returns the projects using another variant of the same type as well as those on other types" do
        expect(filter("!", values).apply_to(Project))
          .to contain_exactly(base_project, other_project)
      end
    end
  end
end
