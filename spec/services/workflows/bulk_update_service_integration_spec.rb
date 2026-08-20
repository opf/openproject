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

RSpec.describe Workflows::BulkUpdateService, "integration", type: :model do
  let(:variant) do
    create(:type).default_variant
  end
  let(:role) do
    create(:project_role)
  end
  let(:status1) do
    create(:status)
  end
  let(:status2) do
    create(:status)
  end
  let(:status3) do
    create(:status)
  end
  let(:status4) do
    create(:status)
  end
  let(:status5) do
    create(:status)
  end

  let(:instance) do
    described_class.new(role:, variant:, tab:)
  end

  describe "#call" do
    let(:params) { {} }

    subject do
      instance.call(params)
    end

    context "with status transitions for everybody" do
      let(:tab) { "always" }
      let(:params) do
        {
          status4.id => { status5.id => ["always"] },
          status3.id => { status1.id => ["always"], status2.id => ["always"] }
        }
      end

      it "sets the workflows" do
        subject

        expect(Workflow.where(type_variant_id: variant.id, role_id: role.id).count)
          .to be 3

        expect(Workflow.where(role_id: role.id,
                              type_variant_id: variant.id,
                              old_status_id: status3.id,
                              new_status_id: status2.id).first).not_to be_nil
        expect(Workflow.where(role_id: role.id,
                              type_variant_id: variant.id,
                              old_status_id: status5.id,
                              new_status_id: status4.id).first).to be_nil
      end
    end

    context "with additional author transitions" do
      let(:tab) { "author" }
      let(:params) do
        {
          status3.id => { status1.id => ["author"] }
        }
      end

      it "sets the workflows" do
        subject

        expect(Workflow.where(type_variant_id: variant.id, role_id: role.id).count)
          .to be 1

        w = Workflow.where(role_id: role.id, type_variant_id: variant.id, old_status_id: status3.id,
                           new_status_id: status1.id).first
        assert w.author
        assert !w.assignee
      end
    end

    context "with additional assignee transitions" do
      let(:tab) { "assignee" }
      let(:params) do
        {
          status3.id => { status2.id => ["assignee"] }
        }
      end

      it "sets the workflows" do
        subject

        expect(Workflow.where(type_variant_id: variant.id, role_id: role.id).count)
          .to be 1

        w = Workflow.where(role_id: role.id, type_variant_id: variant.id, old_status_id: status3.id,
                           new_status_id: status2.id).first
        assert !w.author
        assert w.assignee
      end
    end

    context "without transitions" do
      let(:tab) { "always" }
      let(:params) do
        {}
      end

      before do
        Workflow.create!(role_id: role.id, type_variant_id: variant.id, old_status_id: status3.id, new_status_id: status2.id)
      end

      it "clears all workflows" do
        subject

        expect(Workflow.where(type_variant_id: variant.id, role_id: role.id).count)
          .to be 0
      end
    end

    context "with no params" do
      let(:tab) { "always" }
      let(:params) do
        nil
      end

      before do
        Workflow.create!(role_id: role.id, type_variant_id: variant.id, old_status_id: status3.id, new_status_id: status2.id)
      end

      it "clears all workflows" do
        subject

        expect(Workflow.where(type_variant_id: variant.id, role_id: role.id).count)
          .to be 0
      end
    end
  end
end
