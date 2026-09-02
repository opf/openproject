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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Users::InviteController do
  shared_let(:admin) { create(:admin) }
  shared_let(:project) { create(:project) }
  shared_let(:role) { create(:project_role) }

  before { login_as(admin) }

  def invite(principal_type:, id_or_email:)
    post :step,
         params: {
           step: "principal",
           user_invitation: {
             project_id: project.id,
             principal_type:,
             id_or_email:,
             role_id: role.id,
             message: "Welcome"
           }
         },
         format: :turbo_stream
  end

  def create_required_user_custom_fields
    create(:user_custom_field, :list, is_required: true, editable: false, default_option: "A")
    create(:user_custom_field, :string, is_required: true)
  end

  def create_required_group_custom_fields
    create(:group_custom_field, :list, is_required: true, editable: false, default_option: "A")
    create(:group_custom_field, :string, is_required: true)
  end

  describe "POST #step for the principal step" do
    it "adds an existing user with missing required custom fields" do
      principal = create(:user)
      create_required_user_custom_fields

      invite(principal_type: "User", id_or_email: principal.id)

      expect(response).to have_http_status(:ok)
      expect(project.members.find_by(user_id: principal.id)&.roles).to eq([role])
    end

    it "invites and adds a new user with missing required custom fields" do
      create_required_user_custom_fields

      invite(principal_type: "User", id_or_email: "new-user@example.com")

      principal = User.find_by!(mail: "new-user@example.com")
      expect(response).to have_http_status(:ok)
      expect(principal).to be_invited
      expect(project.members.find_by(user_id: principal.id)&.roles).to eq([role])
    end

    it "adds a group with missing required custom fields" do
      principal = create(:group)
      create_required_group_custom_fields

      invite(principal_type: "Group", id_or_email: principal.id)

      expect(response).to have_http_status(:ok)
      expect(project.members.find_by(user_id: principal.id)&.roles).to eq([role])
    end
  end
end
