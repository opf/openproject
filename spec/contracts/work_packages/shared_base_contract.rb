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

RSpec.shared_examples_for "work package contract" do
  let(:user) { build_stubbed(:user) }
  let(:other_user) { build_stubbed(:user) }
  let(:policy) { double(WorkPackagePolicy, allowed?: true) }

  subject(:contract) { described_class.new(work_package, user) }

  let(:validated_contract) do
    contract = subject
    contract.validate
    contract
  end

  before do
    allow(WorkPackagePolicy)
      .to receive(:new)
      .and_return(policy)
  end

  let(:possible_assignees) { [] }
  let!(:assignable_assignees_scope) do
    scope = double "assignable assignees scope"

    if work_package.persisted?
      allow(Principal)
        .to receive(:possible_assignee)
              .with(work_package)
              .and_return scope
    else
      allow(Principal)
        .to receive(:possible_assignee)
              .with(work_package.project)
              .and_return scope
    end

    allow(scope)
      .to receive(:exists?) do |hash|
      possible_assignees.map(&:id).include?(hash[:id])
    end

    scope
  end

  shared_examples_for "has no error on" do |property|
    it property do
      expect(validated_contract.errors[property]).to be_empty
    end
  end

  describe "assigned_to_id" do
    before do
      work_package.assigned_to_id = other_user.id
    end

    context "if the assigned user is a possible assignee" do
      let(:possible_assignees) { [other_user] }

      it_behaves_like "has no error on", :assigned_to
    end

    context "if the assigned user is not a possible assignee" do
      it "is not a valid assignee" do
        error = I18n.t("api_v3.errors.validation.invalid_user_assigned_to_work_package",
                       property: I18n.t("attributes.assignee"))
        expect(validated_contract.errors[:assigned_to]).to contain_exactly(error)
      end
    end

    context "if the project is not set" do
      let(:work_package_project) { nil }

      it_behaves_like "has no error on", :assigned_to
    end
  end

  describe "responsible_id" do
    before do
      work_package.responsible_id = other_user.id
    end

    context "if the responsible user is a possible responsible" do
      let(:possible_assignees) { [other_user] }

      it_behaves_like "has no error on", :responsible
    end

    context "if the assigned user is not a possible responsible" do
      it "is not a valid responsible" do
        error = I18n.t("api_v3.errors.validation.invalid_user_assigned_to_work_package",
                       property: I18n.t("attributes.responsible"))
        expect(validated_contract.errors[:responsible]).to contain_exactly(error)
      end
    end

    context "if the project is not set" do
      let(:work_package_project) { nil }

      it_behaves_like "has no error on", :responsible
    end
  end

  describe "#assignable_assignees" do
    it "returns the Principal`s possible_assignee scope" do
      expect(subject.assignable_assignees)
        .to eql assignable_assignees_scope
    end
  end

  describe "#assignable_responsibles" do
    it "returns the Principal`s possible_assignee scope" do
      expect(subject.assignable_responsibles)
        .to eql assignable_assignees_scope
    end
  end
end
