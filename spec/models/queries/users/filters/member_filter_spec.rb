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

RSpec.describe Queries::Users::Filters::MemberFilter do
  it_behaves_like "basic query filter" do
    let(:class_key) { :member }
    let(:type) { :list_optional }
    let(:name) { I18n.t(:label_member_of_project) }
  end

  describe "#allowed_values" do
    shared_let(:public_project) { create(:public_project) }
    shared_let(:private_project) { create(:project) }
    shared_let(:archived_project) { create(:public_project, active: false) }
    shared_let(:user) { create(:user, member_with_permissions: { private_project => %i[view_work_packages] }) }

    subject(:allowed_ids) do
      described_class.create!(name: :member, operator: "=", values: []).allowed_values.map(&:last)
    end

    it "offers the projects the current user may see" do
      login_as(user)

      expect(allowed_ids).to contain_exactly(public_project.id, private_project.id)
    end

    it "omits projects the current user cannot see" do
      login_as(create(:user))

      expect(allowed_ids).to contain_exactly(public_project.id)
    end

    it "omits archived projects even for an admin" do
      login_as(create(:admin))

      expect(allowed_ids).to include(public_project.id, private_project.id)
      expect(allowed_ids).not_to include(archived_project.id)
    end
  end

  describe "#apply_to" do
    shared_let(:project) { create(:project) }
    shared_let(:other_project) { create(:project) }
    shared_let(:role) { create(:project_role) }

    shared_let(:member) { create(:user).tap { |user| create(:member, project:, principal: user, roles: [role]) } }
    shared_let(:other_member) do
      create(:user).tap { |user| create(:member, project: other_project, principal: user, roles: [role]) }
    end
    shared_let(:non_member) { create(:user) }

    def filtered(operator, values = [project.id.to_s])
      described_class.create!(name: :member, operator:, values:).apply_to(User.user)
    end

    it "selects the members of the given project for '='" do
      expect(filtered("=")).to contain_exactly(member)
    end

    it "excludes the members of the given project for '!'" do
      expect(filtered("!")).to include(other_member, non_member)
      expect(filtered("!")).not_to include(member)
    end

    it "selects users that are a member of any project for '*'" do
      expect(filtered("*", [])).to include(member, other_member)
      expect(filtered("*", [])).not_to include(non_member)
    end

    it "selects users that are a member of no project for '!*'" do
      expect(filtered("!*", [])).to include(non_member)
      expect(filtered("!*", [])).not_to include(member, other_member)
    end

    context "with memberships that are not project memberships" do
      shared_let(:work_package_member) do
        create(:user).tap do |user|
          create(:work_package_member,
                 entity: create(:work_package, project:),
                 principal: user,
                 roles: [create(:work_package_role)])
        end
      end
      shared_let(:global_member) do
        create(:user).tap { |user| create(:global_member, principal: user, roles: [create(:global_role)]) }
      end

      it "does not count a work package share as project membership" do
        expect(filtered("=")).not_to include(work_package_member)
        expect(filtered("!*", [])).to include(work_package_member)
      end

      it "does not count a global membership as project membership" do
        expect(filtered("*", [])).not_to include(global_member)
        expect(filtered("!*", [])).to include(global_member)
      end
    end
  end
end
