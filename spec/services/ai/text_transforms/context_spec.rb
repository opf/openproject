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

RSpec.describe AI::TextTransforms::Context do
  shared_let(:type) { create(:type) }
  shared_let(:project) { create(:project, types: [type]) }

  describe ".for_work_package" do
    let(:work_package) { create(:work_package, project:, type:) }
    let(:context) { described_class.for_work_package(work_package) }

    it "carries the work package, its project and its type" do
      expect(context).to have_attributes(work_package:, project:, type:)
    end

    it "resolves the type's default variant" do
      expect(context.type_variant).to eq(type.default_variant)
    end

    it "prefers the project's variant of the type" do
      variant = create(:type_variant, type:, variant_name: "Project variant")
      project.project_types.find_by!(type_id: type.id).update!(variant:)

      expect(described_class.for_work_package(work_package.reload).type_variant).to eq(variant)
    end

    it "returns the variant's default description as template" do
      type.default_variant.update!(default_work_package_description: "## Steps")

      expect(context.template).to eq("## Steps")
    end

    it "returns nil for a blank template" do
      type.default_variant.update!(default_work_package_description: "   ")

      expect(context.template).to be_nil
    end
  end

  describe ".for_new_work_package" do
    let(:context) { described_class.for_new_work_package(project:, type:) }

    it "has no work package" do
      expect(context).to have_attributes(work_package: nil, project:, type:)
    end

    it "resolves the variant through the project" do
      expect(context.type_variant).to eq(project.type_variant(type))
    end

    it "returns the template of the resolved variant" do
      type.default_variant.update!(default_work_package_description: "## Steps")

      expect(context.template).to eq("## Steps")
    end
  end

  describe ".none" do
    let(:context) { described_class.none }

    it "has neither type nor variant nor template" do
      expect(context).to have_attributes(work_package: nil, project: nil, type: nil)
      expect(context.type_variant).to be_nil
      expect(context.template).to be_nil
    end
  end
end
