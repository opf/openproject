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
require_relative "shared_contract_examples"

RSpec.describe Groups::UpdateContract do
  it_behaves_like "group contract" do
    let(:group) do
      build_stubbed(:group,
                    name: group_name,
                    group_users:)
    end

    let(:contract) { described_class.new(group, current_user) }

    describe "validations" do
      let(:current_user) { build_stubbed(:admin) }

      describe "type" do
        before do
          group.type = "A new type"
        end

        it_behaves_like "contract is invalid", type: :error_readonly
      end

      describe "organizational_unit" do
        it "is not a writable attribute" do
          expect(contract.writable_attributes).not_to include("organizational_unit")
        end
      end
    end
  end

  describe "department user uniqueness validation" do
    let(:current_user) { create(:admin) }
    let(:user) { create(:user) }

    context "when adding a user to a department who is already in another department" do
      let(:other_department) { create(:department, members: [user]) }
      let(:department) { create(:department) }
      let(:contract) { described_class.new(department, current_user) }

      before do
        other_department
        department.group_users.build(user_id: user.id)
      end

      it "is invalid with user and department details" do
        expect(contract.validate).to be false

        group_users_errors = contract.errors.where(:group_users)
        expect(group_users_errors.map(&:type)).to include(:user_already_in_department)

        error = group_users_errors.find { |e| e.type == :user_already_in_department }
        expect(error.options[:user_id]).to eq(user.id)
        expect(error.options[:department_id]).to eq(other_department.id)
      end
    end

    context "when adding multiple users who are each in different departments" do
      let(:other_user) { create(:user) }
      let(:department_a) { create(:department, members: [user]) }
      let(:department_b) { create(:department, members: [other_user]) }
      let(:department) { create(:department) }
      let(:contract) { described_class.new(department, current_user) }

      before do
        department_a
        department_b
        department.group_users.build(user_id: user.id)
        department.group_users.build(user_id: other_user.id)
      end

      it "adds an error for each user" do
        expect(contract.validate).to be false

        dept_errors = contract.errors.where(:group_users).select { |e| e.type == :user_already_in_department }
        expect(dept_errors.length).to eq(2)

        error_details = dept_errors.map { |e| { user_id: e.options[:user_id], department_id: e.options[:department_id] } }
        expect(error_details).to contain_exactly(
          { user_id: user.id, department_id: department_a.id },
          { user_id: other_user.id, department_id: department_b.id }
        )
      end
    end

    context "when adding a user to a department who is not in any department" do
      let(:department) { create(:department) }
      let(:contract) { described_class.new(department, current_user) }

      before do
        department.group_users.build(user_id: user.id)
      end

      it "is valid" do
        expect(contract.validate).to be true
      end
    end

    context "when adding a user to a regular group who is already in a department" do
      let(:department) { create(:department, members: [user]) }
      let(:group) { create(:group) }
      let(:contract) { described_class.new(group, current_user) }

      before do
        department
        group.group_users.build(user_id: user.id)
      end

      it "is valid" do
        expect(contract.validate).to be true
      end
    end
  end
end
