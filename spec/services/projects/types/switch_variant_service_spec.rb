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

require "spec_helper"

RSpec.describe Projects::Types::SwitchVariantService, with_flag: { type_variants: true } do
  subject(:service_call) { described_class.new(user:, model: project).call(source:, target:) }

  let(:user) { create(:admin) }
  let(:type) { create(:type) }
  let(:base_variant) { type.default_variant }
  let(:variant) { create(:type_variant, type:) }
  let(:sibling_variant) { create(:type_variant, type:) }
  let(:project) { create(:project, types: [variant]) }
  let!(:work_package) { create(:work_package, project:, type:) }

  let(:source) { variant }
  let(:target) { sibling_variant }

  def resolved_variant = project.reload.project_types.sole.variant

  context "when switching to a sibling variant" do
    it "resolves the project to the target" do
      expect(service_call).to be_success
      expect(resolved_variant).to eq(sibling_variant)
      expect(project.enabled_types).to contain_exactly(type)
    end

    it "leaves the work packages alone" do
      expect { service_call }.not_to change { work_package.reload.attributes }
    end

    it "journals nothing" do
      expect { service_call }.not_to change(Journal, :count)
    end
  end

  context "when switching to the base variant" do
    let(:target) { base_variant }

    it "resolves the project to the type's own configuration" do
      expect(service_call).to be_success
      expect(resolved_variant).to eq(base_variant)
    end
  end

  # A project on a type's base variant still has the named ones to offer, so the switch has
  # to work in this direction too.
  context "when switching from the base variant to a named one" do
    let(:project) { create(:project, types: [type]) }
    let(:source) { base_variant }
    let(:target) { variant }

    it "resolves the project to the target" do
      expect(service_call).to be_success
      expect(resolved_variant).to eq(variant)
      expect(project.enabled_types).to contain_exactly(type)
    end

    it "leaves the work packages alone" do
      expect { service_call }.not_to change { work_package.reload.attributes }
    end
  end

  context "when the target is identical to the source" do
    let(:target) { variant }

    it "fails" do
      expect(service_call).to be_failure
      expect(service_call.errors.symbols_for(:types)).to contain_exactly(:switch_target_identical)
    end
  end

  context "when the target belongs to a different type" do
    let(:target) { create(:type_variant) }

    it "fails" do
      expect(service_call).to be_failure
      expect(service_call.errors.symbols_for(:types)).to contain_exactly(:switch_target_not_in_family)
    end
  end

  # Refused rather than raised on: the caller reaches the service with whatever the request
  # resolved to, and an unknown id resolves to nothing.
  context "when no target was given" do
    let(:target) { nil }

    it "fails without changing anything" do
      expect(service_call).to be_failure
      expect(service_call.errors.symbols_for(:types)).to contain_exactly(:switch_target_blank)
      expect(resolved_variant).to eq(variant)
    end
  end

  context "when the user may not author the project's variants" do
    let(:user) { create(:user) }

    it "fails without changing anything" do
      expect(service_call).to be_failure
      expect(service_call.errors.symbols_for(:base)).to contain_exactly(:error_unauthorized)
      expect(resolved_variant).to eq(variant)
    end
  end
end
