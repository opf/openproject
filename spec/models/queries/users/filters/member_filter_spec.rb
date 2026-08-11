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

  describe "the project values" do
    shared_let(:public_project) { create(:public_project) }
    shared_let(:private_project) { create(:project) }
    shared_let(:user) { create(:user, member_with_permissions: { private_project => %i[view_work_packages] }) }

    let(:instance) { described_class.create!(name: :member, operator: "=", values: [private_project.id.to_s]) }

    before { login_as(user) }

    it "offers the projects the current user may see" do
      expect(instance.allowed_values.map(&:last))
        .to contain_exactly(public_project.id.to_s, private_project.id.to_s)
    end

    it "omits projects the current user cannot see" do
      login_as(create(:user))

      expect(instance.allowed_values.map(&:last)).to contain_exactly(public_project.id.to_s)
    end

    it "resolves the selected values to visible projects" do
      expect(instance.value_objects).to contain_exactly(private_project)
    end

    # The UI picks projects through the autocompleter, so the filter does not have
    # to enumerate them for validation.
    it "is validated as a list of integers rather than against the project list" do
      expect(instance.type_strategy).to be_a(Queries::Filters::Strategies::IntegerListOptional)
      expect(described_class.create!(name: :member, operator: "=", values: ["-42"])).to be_valid
    end

    it "autocompletes against the active projects" do
      expect(instance.autocomplete_options)
        .to include(component: "opce-project-autocompleter",
                    resource: "projects",
                    filters: [{ name: "active", operator: "=", values: ["t"] }])
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
