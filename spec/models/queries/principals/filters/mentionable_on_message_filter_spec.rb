# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe Queries::Principals::Filters::MentionableOnMessageFilter do
  it_behaves_like "basic query filter" do
    let(:class_key) { :mentionable_on_message }
    let(:type) { :list_optional }
    let(:human_name) { "mentionable" }

    describe "#scope" do
      subject { instance.apply_to(Principal) }

      shared_let(:project) { create(:project) }
      shared_let(:other_project) { create(:project) }
      shared_let(:role) { create(:project_role, permissions: %i[]) }
      shared_let(:message) { create(:message, forum: create(:forum, project:)) }

      shared_let(:user) { create(:user, member_with_roles: { project => role, other_project => role }) }
      shared_let(:project_member) { create(:user, member_with_roles: { project => role }) }
      shared_let(:other_project_member) { create(:user, member_with_roles: { other_project => role }) }
      shared_let(:group) do
        create(:group).tap { |group| create(:member, principal: group, project:, roles: [role]) }
      end

      let(:values) { [message.id.to_s] }

      let(:instance) do
        described_class.create!.tap do |filter|
          filter.values = values
          filter.operator = operator
        end
      end

      current_user { user }

      context "with an = operator" do
        let(:operator) { "=" }

        it "returns the members of the message's project" do
          expect(subject).to contain_exactly(user, project_member, group)
        end
      end

      context "with a ! operator" do
        let(:operator) { "!" }

        it "returns the visible principals outside the message's project" do
          expect(subject).to contain_exactly(other_project_member)
        end
      end

      context "with a message the current user cannot see" do
        let(:operator) { "=" }
        let(:values) { [create(:message, forum: create(:forum, project: create(:project))).id.to_s] }

        it "is invalid" do
          expect(instance).not_to be_valid
        end
      end
    end
  end
end
