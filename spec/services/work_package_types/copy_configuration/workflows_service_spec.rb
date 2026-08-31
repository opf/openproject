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

RSpec.describe WorkPackageTypes::CopyConfiguration::WorkflowsService do
  shared_let(:admin) { create(:admin) }
  shared_let(:role) { create(:project_role) }
  shared_let(:statuses) { create_list(:status, 2) }

  let(:variant) { create(:type).default_variant }

  subject(:service_call) { described_class.new(variant:, user: admin).call(source:) }

  describe "#call" do
    context "with a source" do
      let(:source) { create(:type).default_variant }

      before do
        create(:workflow, type: source, role_id: role.id,
                          old_status_id: statuses[0].id, new_status_id: statuses[1].id,
                          author: false, assignee: false)
      end

      it "copies the source's transitions onto the variant" do
        expect(service_call).to be_success
        expect(Workflow.exists?(type_variant_id: variant.id, role_id: role.id,
                                old_status_id: statuses[0].id, new_status_id: statuses[1].id)).to be(true)
      end
    end

    context "when the variant already has transitions" do
      let(:source) { create(:type).default_variant }

      before do
        create(:workflow, type: variant, role_id: role.id,
                          old_status_id: statuses[1].id, new_status_id: statuses[0].id,
                          author: false, assignee: false)
        create(:workflow, type: source, role_id: role.id,
                          old_status_id: statuses[0].id, new_status_id: statuses[1].id,
                          author: false, assignee: false)
      end

      it "replaces the variant's transitions with the source's" do
        expect(service_call).to be_success
        expect(Workflow.exists?(type_variant_id: variant.id, role_id: role.id,
                                old_status_id: statuses[1].id, new_status_id: statuses[0].id)).to be(false)
        expect(Workflow.exists?(type_variant_id: variant.id, role_id: role.id,
                                old_status_id: statuses[0].id, new_status_id: statuses[1].id)).to be(true)
      end
    end

    context "when the source resolves through a link", with_flag: { type_variants: true } do
      let(:owner) { create(:type).default_variant }
      let(:source) { create(:type).default_variant }

      before do
        create(:workflow, type: owner, role_id: role.id,
                          old_status_id: statuses[0].id, new_status_id: statuses[1].id,
                          author: false, assignee: false)
        link_configuration(source, source: owner, aspect: TypeVariant::WORKFLOWS)
      end

      it "adopts the resolved owner's transitions" do
        expect(Workflow.exists?(type_variant_id: variant.id, role_id: role.id,
                                old_status_id: statuses[0].id, new_status_id: statuses[1].id)).to be(false)

        expect(service_call).to be_success
        expect(Workflow.exists?(type_variant_id: variant.id, role_id: role.id,
                                old_status_id: statuses[0].id, new_status_id: statuses[1].id)).to be(true)
      end
    end

    context "when the source resolves through a longer chain", with_flag: { type_variants: true } do
      let(:owner) { create(:type).default_variant }
      let(:middle) { create(:type).default_variant }
      let(:source) { create(:type).default_variant }

      before do
        create(:workflow, type: owner, role_id: role.id,
                          old_status_id: statuses[0].id, new_status_id: statuses[1].id,
                          author: false, assignee: false)
        link_configuration(middle, source: owner, aspect: TypeVariant::WORKFLOWS)
        link_configuration(source, source: middle, aspect: TypeVariant::WORKFLOWS)
      end

      it "adopts the resolved owner's transitions" do
        expect(Workflow.exists?(type_variant_id: variant.id, role_id: role.id,
                                old_status_id: statuses[0].id, new_status_id: statuses[1].id)).to be(false)
        expect(service_call).to be_success
        expect(Workflow.exists?(type_variant_id: variant.id, role_id: role.id,
                                old_status_id: statuses[0].id, new_status_id: statuses[1].id)).to be(true)
      end
    end

    context "with an invalid source" do
      let(:source) { nil }

      it "fails without changing the variant" do
        expect(service_call).not_to be_success
      end
    end

    context "when the source is the variant itself" do
      let(:source) { variant }

      it "fails" do
        expect(service_call).not_to be_success
      end
    end
  end
end
