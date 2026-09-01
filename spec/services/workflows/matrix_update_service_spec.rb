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

RSpec.describe Workflows::MatrixUpdateService, type: :model do
  shared_let(:variant) { create(:type).default_variant }
  shared_let(:role) { create(:project_role) }
  shared_let(:other_role) { create(:project_role) }
  shared_let(:status_a) { create(:status) }
  shared_let(:status_b) { create(:status) }
  shared_let(:status_c) { create(:status) }

  subject(:service_call) { instance.call(**call_params) }

  let(:instance) { described_class.new(variant:, roles:, tab:) }
  let(:roles) { [role] }
  let(:tab) { "always" }
  let(:call_params) { { status: } }
  let(:status) { { status_a.id.to_s => { status_b.id.to_s => ["always"] } } }

  def transitions_for(a_role, author: false, assignee: false)
    Workflow
      .where(type_variant_id: variant.id, role_id: a_role.id, author:, assignee:)
      .pluck(:old_status_id, :new_status_id)
  end

  it "persists the submitted transitions" do
    expect(service_call).to be_success
    expect(transitions_for(role)).to contain_exactly([status_a.id, status_b.id])
  end

  it "replaces transitions that are no longer submitted" do
    create(:workflow, role_id: role.id, type_variant_id: variant.id,
                      old_status_id: status_b.id, new_status_id: status_c.id)

    expect(service_call).to be_success
    expect(transitions_for(role)).to contain_exactly([status_a.id, status_b.id])
  end

  context "with several roles selected" do
    let(:roles) { [role, other_role] }

    it "persists the same transitions for each role" do
      expect(service_call).to be_success

      expect(transitions_for(role)).to contain_exactly([status_a.id, status_b.id])
      expect(transitions_for(other_role)).to contain_exactly([status_a.id, status_b.id])
    end

    context "when a transition is indeterminate because only one role has it" do
      let(:call_params) do
        { status:, indeterminate_status: { status_b.id.to_s => { status_c.id.to_s => "1" } } }
      end

      before do
        create(:workflow, role_id: role.id, type_variant_id: variant.id,
                          old_status_id: status_b.id, new_status_id: status_c.id)
      end

      it "keeps the transition for the role that had it and does not add it to the others" do
        expect(service_call).to be_success

        expect(transitions_for(role))
          .to contain_exactly([status_a.id, status_b.id], [status_b.id, status_c.id])
        expect(transitions_for(other_role))
          .to contain_exactly([status_a.id, status_b.id])
      end
    end

    context "when one role fails to persist" do
      before do
        allow(Workflows::BulkUpdateService)
          .to receive(:new).and_call_original

        allow(Workflows::BulkUpdateService)
          .to receive(:new).with(role: other_role, variant:, tab:)
          .and_return(instance_double(Workflows::BulkUpdateService, call: ServiceResult.failure))
      end

      it "rolls back the roles that did succeed" do
        expect(service_call).to be_failure
        expect(transitions_for(role)).to be_empty
      end
    end
  end

  describe "tabs" do
    let(:tab) { "author" }

    it "writes the transitions against the tab's flag only" do
      expect(service_call).to be_success

      expect(transitions_for(role, author: true)).to contain_exactly([status_a.id, status_b.id])
      expect(transitions_for(role)).to be_empty
    end
  end

  describe "when the workflows aspect is linked to a source variant" do
    shared_let(:source_variant) { create(:type).default_variant }

    before { variant.update!(workflows_source: source_variant) }
    after { variant.update!(workflows_source: nil) }

    it "persists nothing and reports success" do
      expect(service_call).to be_success
      expect(transitions_for(role)).to be_empty
    end
  end

  describe "matrix sanitizing" do
    context "with ActionController::Parameters" do
      let(:status) do
        ActionController::Parameters.new(status_a.id.to_s => { status_b.id.to_s => ["always"] })
      end

      it "persists the transitions" do
        expect(service_call).to be_success
        expect(transitions_for(role)).to contain_exactly([status_a.id, status_b.id])
      end
    end

    context "with non-numeric keys" do
      let(:status) do
        {
          status_a.id.to_s => { status_b.id.to_s => ["always"] },
          "utf8" => { "✓" => "1" },
          status_b.id.to_s => "not-a-nested-hash"
        }
      end

      it "ignores everything that did not come from the rendered matrix" do
        expect(service_call).to be_success
        expect(transitions_for(role)).to contain_exactly([status_a.id, status_b.id])
      end
    end

    context "with no matrix submitted at all" do
      let(:call_params) { {} }

      before do
        create(:workflow, role_id: role.id, type_variant_id: variant.id,
                          old_status_id: status_a.id, new_status_id: status_b.id)
      end

      it "clears the tab's transitions" do
        expect(service_call).to be_success
        expect(transitions_for(role)).to be_empty
      end
    end
  end
end
