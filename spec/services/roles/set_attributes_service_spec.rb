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

RSpec.describe Roles::SetAttributesService, type: :model do
  let(:current_user) { build_stubbed(:admin) }

  let(:contract_instance) do
    contract = instance_double(Roles::CreateContract, "contract_instance")
    allow(contract).to receive(:validate).and_return(contract_valid)
    allow(contract).to receive(:errors).and_return(contract_errors)
    contract
  end

  let(:contract_errors) { instance_double(ActiveModel::Errors, "contract_errors") }
  let(:contract_valid) { true }
  let(:model_valid) { true }

  let(:instance) do
    described_class.new(user: current_user, model: model_instance, contract_class:, contract_options: {})
  end
  let(:model_instance) { ProjectRole.new }
  let(:contract_class) do
    allow(Roles::CreateContract).to receive(:new).and_return(contract_instance)

    Roles::CreateContract
  end

  let(:params) { {} }
  let(:permissions) { %i[view_work_packages view_wiki_pages] }

  before do
    allow(model_instance).to receive(:valid?).and_return(model_valid)
  end

  subject { instance.call(params) }

  it "returns the instance as the result" do
    expect(subject.result).to eql model_instance
  end

  it "is a success" do
    expect(subject).to be_success
  end

  context "with params" do
    let(:params) do
      {
        permissions:
      }
    end

    before do
      create(:non_member, permissions: %i[view_meetings view_wiki_pages])
      subject
    end

    context "with a ProjectRole" do
      it "assigns the params with the public permissions" do
        expect(model_instance.permissions).to match_array(OpenProject::AccessControl.public_permissions.map(&:name) + permissions)
      end

      context "when no permissions are given" do
        let(:permissions) { [] }

        it "assigns the permissions the non member role has" do
          expect(model_instance.permissions).to match_array(ProjectRole.non_member.permissions) # public permissions are included via the factory
        end
      end
    end

    context "with a GlobalRole" do
      let(:model_instance) { GlobalRole.new }

      it "assigns the params" do
        expect(model_instance.permissions).to match_array(permissions)
      end

      context "when no permissions are given" do
        let(:permissions) { [] }

        it "assigns nothing" do
          expect(model_instance.permissions).to be_empty
        end
      end
    end

    context "with a WorkPackageRole" do
      let(:model_instance) { WorkPackageRole.new }

      it "assigns the params" do
        expect(model_instance.permissions).to match_array(permissions)
      end

      context "when no permissions are given" do
        let(:permissions) { [] }

        it "assigns nothing" do
          expect(model_instance.permissions).to be_empty
        end
      end
    end
  end

  context "with an invalid contract" do
    let(:contract_valid) { false }

    it "returns failure" do
      expect(subject).not_to be_success
    end

    it "returns the contract's errors" do
      expect(subject.errors)
        .to eql(contract_errors)
    end
  end
end
