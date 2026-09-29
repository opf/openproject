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

RSpec.describe "ResourceManagement PlaceholderUsers requests",
               :skip_csrf, type: :rails_request,
                           with_ee: %i[resource_management placeholder_users] do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }
  shared_let(:user) do
    create(:user,
           global_permissions: %i[manage_placeholder_user],
           member_with_permissions: { project => %i[view_resource_planners allocate_user_resources] })
  end

  let(:criteria) { [{ name: { operator: "~", values: ["dev"] } }].to_json }

  before { login_as user }

  describe "GET new" do
    it "opens the dialog with the name pre-filled from the search term" do
      get new_resource_management_placeholder_user_path(name: "Backend Developer"), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("resource_management.create_placeholder_user_dialog.title"))
      expect(response.body).to include("placeholder_user[name]", "Backend Developer")
      expect(response.body).to include("placeholder_user[description]")
    end

    it "offers the filter builder to describe who the placeholder stands for" do
      get new_resource_management_placeholder_user_path, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("op-filters-form")
    end
  end

  describe "POST create" do
    subject(:perform) do
      post resource_management_placeholder_users_path,
           params: {
             placeholder_user: { name: "Backend Developer", description: "Someone who knows Ruby" },
             filters: criteria
           },
           as: :turbo_stream
    end

    it "creates the placeholder user with its criteria" do
      expect { perform }.to change(PlaceholderUser, :count).by(1)

      placeholder_user = PlaceholderUser.last
      expect(placeholder_user.name).to eq("Backend Developer")
      expect(placeholder_user.description).to eq("Someone who knows Ruby")
      expect(placeholder_user.user_filter.map(&:field)).to eq([:name])
      expect(PlaceholderUser.allocatable(user)).to include(placeholder_user)
    end

    it "closes the dialog, handing over the new placeholder user's id" do
      perform

      expect(response).to have_http_status(:ok)
      expect(response).to have_turbo_stream(
        action: "closeDialog",
        target: ResourceManagement::PlaceholderUsers::NewDialogComponent::DIALOG_ID
      )
      expect(response.body).to include(CGI.escapeHTML({ placeholderUserId: PlaceholderUser.last.id }.to_json))
    end

    context "without any criteria" do
      subject(:perform) do
        post resource_management_placeholder_users_path,
             params: { placeholder_user: { name: "Backend Developer" }, filters: [].to_json },
             as: :turbo_stream
      end

      it "refuses to create a placeholder nothing can be allocated against" do
        expect { perform }.not_to change(PlaceholderUser, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include(
          CGI.escapeHTML("#{PlaceholderUser.human_attribute_name(:user_filter)} " \
                         "#{I18n.t('activerecord.errors.messages.blank')}")
        )
      end
    end

    context "with an invalid name" do
      subject(:perform) do
        post resource_management_placeholder_users_path,
             params: { placeholder_user: { name: "" }, filters: criteria },
             as: :turbo_stream
      end

      it "re-renders the form" do
        expect { perform }.not_to change(PlaceholderUser, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("placeholder_user[name]")
      end
    end
  end

  describe "without the manage_placeholder_user permission" do
    shared_let(:allocator) do
      create(:user, member_with_permissions: { project => %i[view_resource_planners allocate_user_resources] })
    end

    before { login_as allocator }

    it "denies opening the dialog" do
      get new_resource_management_placeholder_user_path, as: :turbo_stream

      expect(response).to have_http_status(:forbidden)
    end

    it "denies creating a placeholder user" do
      expect do
        post resource_management_placeholder_users_path,
             params: { placeholder_user: { name: "Backend Developer" }, filters: criteria },
             as: :turbo_stream
      end.not_to change(PlaceholderUser, :count)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
