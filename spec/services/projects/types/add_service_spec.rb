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

RSpec.describe Projects::Types::AddService do
  subject(:service_call) { described_class.new(user:, model: project).call(type:) }

  let(:user) { create(:admin) }
  let(:project) { create(:project, no_types: true) }

  context "with a root type" do
    let(:type) { create(:type) }

    it "enables the type on the project" do
      expect(service_call).to be_success
      expect(project.reload.types).to contain_exactly(type)
    end

    it "enables the type's work package custom fields on the project" do
      custom_field = create(:text_wp_custom_field, types: [type])

      expect { service_call }
        .to change { project.reload.work_package_custom_field_ids }
        .from([])
        .to([custom_field.id])
    end

    context "when the type is already enabled" do
      let(:project) { create(:project, types: [type]) }

      it "succeeds without enabling it twice" do
        expect(service_call).to be_success
        expect(project.reload.types).to contain_exactly(type)
      end
    end
  end

  context "with a subtype" do
    let(:parent_type) { create(:type) }
    let(:type) { create(:type, parent: parent_type) }

    context "and the subtypes feature is not active", with_flag: { subtypes: false } do
      it "fails and does not enable the type" do
        expect(service_call).to be_failure
        expect(service_call.errors.symbols_for(:types)).to contain_exactly(:cannot_assign_subtypes_yet)
        expect(project.reload.types).to be_empty
      end
    end

    context "and the subtypes feature is active", with_flag: { subtypes: true } do
      it "enables the subtype on the project" do
        expect(service_call).to be_success
        expect(project.reload.types).to contain_exactly(type)
      end

      context "when a sibling subtype is already enabled" do
        let(:sibling) { create(:type, parent: parent_type) }
        let(:project) { create(:project, types: [sibling]) }

        it "fails and keeps only the sibling enabled" do
          expect(service_call).to be_failure
          expect(service_call.errors.symbols_for(:types))
            .to contain_exactly(:cannot_assign_multiple_subtypes_of_parent)
          expect(project.reload.types).to contain_exactly(sibling)
        end
      end

      context "when the parent type is already enabled" do
        let(:project) { create(:project, types: [parent_type]) }

        it "fails and keeps only the parent enabled" do
          expect(service_call).to be_failure
          expect(service_call.errors.symbols_for(:types)).to contain_exactly(:cannot_assign_subtype_and_parent)
          expect(project.reload.types).to contain_exactly(parent_type)
        end
      end
    end
  end

  context "with a root type whose subtype is already enabled", with_flag: { subtypes: true } do
    let(:type) { create(:type) }
    let(:subtype) { create(:type, parent: type) }
    let(:project) { create(:project, types: [subtype]) }

    it "fails and keeps only the subtype enabled" do
      expect(service_call).to be_failure
      expect(service_call.errors.symbols_for(:types)).to contain_exactly(:cannot_assign_subtype_and_parent)
      expect(project.reload.types).to contain_exactly(subtype)
    end
  end

  context "when the user is not allowed to manage types" do
    let(:user) { create(:user) }
    let(:type) { create(:type) }

    it "fails without enabling the type" do
      expect(service_call).to be_failure
      expect(service_call.errors.symbols_for(:base)).to contain_exactly(:error_unauthorized)
      expect(project.reload.types).to be_empty
    end
  end
end
