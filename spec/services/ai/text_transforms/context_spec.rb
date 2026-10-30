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

RSpec.describe AI::TextTransforms::Context do
  shared_let(:type) { create(:type) }
  shared_let(:project) { create(:project, types: [type]) }

  describe ".for_work_package" do
    let(:work_package) { create(:work_package, project:, type:) }
    let(:context) { described_class.for_work_package(work_package) }

    it "carries the work package, its project and its type" do
      expect(context).to have_attributes(work_package:, project:, type:)
    end

    it "is identified by the work package" do
      expect(context.ids).to eq(work_package_id: work_package.id)
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

    it "is identified by the project and the type" do
      expect(context.ids).to eq(project_id: project.id, type_id: type.id)
    end

    it "resolves the variant through the project" do
      expect(context.type_variant).to eq(project.type_variant(type))
    end

    it "returns the template of the resolved variant" do
      type.default_variant.update!(default_work_package_description: "## Steps")

      expect(context.template).to eq("## Steps")
    end

    it "resolves the variant once" do
      allow(project).to receive(:type_variant).and_call_original

      3.times { context.template }

      expect(project).to have_received(:type_variant).once
    end
  end

  describe "#ids" do
    let(:user) do
      create(:user, member_with_permissions: { project => %i[view_work_packages edit_work_packages add_work_packages] })
    end
    let(:work_package) { create(:work_package, project:, type:) }

    {
      "a work package" => -> { described_class.for_work_package(work_package) },
      "a new work package" => -> { described_class.for_new_work_package(project:, type:) },
      "no object" => -> { described_class.none }
    }.each do |name, build_context|
      it "resolves back to the context of #{name} through the pane parameters" do
        context = instance_exec(&build_context)
        params = AI::TextTransforms::PaneParamsContract.new.call(request_id: SecureRandom.uuid, scope: "document", **context.ids)

        expect(params).to be_success
        resolved = AI::TextTransforms::ResolveContext.new(user:).call(**params.to_h.slice(*context.ids.keys)).result
        expect(resolved).to have_attributes(work_package: context.work_package, project: context.project, type: context.type)
      end
    end
  end

  describe ".none" do
    let(:context) { described_class.none }

    it "has neither type nor variant nor template" do
      expect(context).to have_attributes(work_package: nil, project: nil, type: nil)
      expect(context.type_variant).to be_nil
      expect(context.template).to be_nil
      expect(context.ids).to eq({})
    end
  end
end
