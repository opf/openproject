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

RSpec.describe Projects::Types::RemoveService do
  subject(:service_call) { described_class.new(user:, model: project).call(variant:) }

  let(:user) { create(:admin) }
  let(:type) { create(:type) }
  let(:variant) { type.default_variant }
  let(:other_type) { create(:type) }
  let(:project) { create(:project, types: [type, other_type]) }

  context "when no work package uses the type" do
    it "disables the type on the project" do
      expect(service_call).to be_success
      expect(project.enabled_types).to contain_exactly(other_type)
    end
  end

  context "when a work package in the project uses the type" do
    before do
      create(:work_package, project:, type:)
    end

    it "fails and keeps the type enabled" do
      expect(service_call).to be_failure
      expect(service_call.errors.symbols_for(:types)).to contain_exactly(:in_use_by_work_packages)
      expect(project.enabled_types).to contain_exactly(type, other_type)
    end
  end

  context "when a work package in another project uses the type" do
    before do
      create(:work_package, type:)
    end

    it "disables the type on the project" do
      expect(service_call).to be_success
      expect(project.enabled_types).to contain_exactly(other_type)
    end
  end

  context "when the type is not enabled on the project" do
    let(:project) { create(:project, types: [other_type]) }

    it "succeeds as a no-op" do
      expect(service_call).to be_success
      expect(project.enabled_types).to contain_exactly(other_type)
    end
  end

  context "when the project applies a named variant", with_flag: { type_variants: true } do
    let(:variant) { create(:type_variant, type:) }
    let(:project) { create(:project, types: [variant, other_type]) }

    it "stops using the type when given the applied variant" do
      expect(service_call).to be_success
      expect(project.enabled_types).to contain_exactly(other_type)
    end

    it "stops using the type when given its base variant" do
      expect(described_class.new(user:, model: project).call(variant: type.default_variant)).to be_success
      expect(project.enabled_types).to contain_exactly(other_type)
    end

    it "refuses while a work package of the type exists" do
      create(:work_package, project:, type:)

      expect(service_call).to be_failure
      expect(service_call.errors.symbols_for(:types)).to contain_exactly(:in_use_by_work_packages)
      expect(project.enabled_types).to contain_exactly(type, other_type)
    end
  end

  context "when the user is not allowed to manage types" do
    let(:user) { create(:user) }

    it "fails without disabling the type" do
      expect(service_call).to be_failure
      expect(service_call.errors.symbols_for(:base)).to contain_exactly(:error_unauthorized)
      expect(project.enabled_types).to contain_exactly(type, other_type)
    end
  end
end
