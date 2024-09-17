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

RSpec.describe "filter me value", :js do
  let(:status) { create(:default_status) }
  let!(:priority) { create(:default_priority) }
  let(:project) do
    create(:project,
           public: true,
           members: project_members)
  end
  let(:role) { create(:existing_project_role, permissions: %i[view_work_packages work_package_assigned]) }
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:filters) { Components::WorkPackages::Filters.new }
  let(:project_members) do
    {
      admin => role,
      user => role
    }
  end
  let!(:role_anonymous) { create(:anonymous_role, permissions: [:view_work_packages]) }

  describe "assignee" do
    let(:wp_admin) { create(:work_package, status:, project:, assigned_to: admin) }
    let(:wp_user) { create(:work_package, status:, project:, assigned_to: user) }

    context "as anonymous", with_settings: { login_required?: false } do
      current_user { User.anonymous }

      let(:assignee_query) do
        query = create(:query,
                       name: "Assignee Query",
                       project:,
                       user:)

        query.add_filter("assigned_to_id", "=", ["me"])
        query.save!(validate: false)

        query
      end

      it "shows an error visiting a query with a me value" do
        wp_table.visit_query assignee_query
        wp_table.expect_toast(type: :error,
                              message: I18n.t("js.work_packages.faulty_query.description"))
      end
    end

    context "logged in" do
      current_user { admin }

      before do
        wp_admin
        wp_user
      end

      it "shows the one work package filtering for myself" do
        wp_table.visit!
        wp_table.expect_work_package_listed(wp_admin, wp_user)

        # Add and save query with me filter
        filters.open
        filters.remove_filter "status"
        filters.add_filter_by("Assignee", "is (OR)", "me")

        wp_table.ensure_work_package_not_listed!(wp_user)
        wp_table.expect_work_package_listed(wp_admin)

        wp_table.save_as("Me query")
        loading_indicator_saveguard

        # Expect correct while saving
        wp_table.expect_title "Me query"
        query = Query.last
        expect(query.filters.first.values).to eq ["me"]
        filters.expect_filter_by("Assignee", "is (OR)", "me")

        # Revisit query
        wp_table.visit_query query
        wp_table.ensure_work_package_not_listed!(wp_user)
        wp_table.expect_work_package_listed(wp_admin)

        filters.open
        filters.expect_filter_by("Assignee", "is (OR)", "me")

        # Expect new work packages receive assignee
        split_screen = wp_table.create_wp_by_button wp_user.type

        # Wait a bit for the page to load
        sleep 2

        subject = split_screen.edit_field :subject
        subject.set_value "foobar"
        subject.submit_by_enter

        split_screen.expect_and_dismiss_toaster message: "Successful creation."

        wp = WorkPackage.last
        expect(wp.assigned_to_id).to eq(admin.id)
      end
    end
  end

  describe "custom_field of type user" do
    let(:custom_field) do
      create(
        :user_wp_custom_field,
        name: "CF user",
        is_required: false
      )
    end
    let(:type_task) { create(:type_task, custom_fields: [custom_field]) }
    let(:project) do
      create(:project,
             types: [type_task],
             public: true,
             work_package_custom_fields: [custom_field],
             members: project_members)
    end

    let(:cf_accessor) { custom_field.attribute_name }
    let(:cf_accessor_frontend) { cf_accessor.camelcase(:lower) }
    let(:wp_admin) do
      create(:work_package,
             type: type_task,
             project:,
             custom_field_values: { custom_field.id => admin.id })
    end

    let(:wp_user) do
      create(:work_package,
             type: type_task,
             project:,
             custom_field_values: { custom_field.id => user.id })
    end

    context "as anonymous", with_settings: { login_required?: false } do
      let(:assignee_query) do
        query = create(:query,
                       name: "CF user Query",
                       project:,
                       user:)

        query.add_filter(cf_accessor, "=", ["me"])
        query.save!(validate: false)

        query
      end

      current_user { User.anonymous }

      it "shows an error visiting a query with a me value" do
        wp_table.visit_query assignee_query
        wp_table.expect_toast(type: :error,
                              message: I18n.t("js.work_packages.faulty_query.description"))
      end
    end

    context "logged in" do
      current_user { admin }

      before do
        wp_admin
        wp_user
      end

      it "shows the one work package filtering for myself" do
        wp_table.visit!
        wp_table.expect_work_package_listed(wp_admin, wp_user)

        # Add and save query with me filter
        filters.open
        filters.remove_filter "status"
        filters.add_filter_by("CF user", "is (OR)", "me", cf_accessor_frontend)

        wp_table.ensure_work_package_not_listed!(wp_user)
        wp_table.expect_work_package_listed(wp_admin)

        wp_table.save_as("Me query")
        loading_indicator_saveguard

        # Expect correct while saving
        wp_table.expect_title "Me query"
        query = Query.last
        expect(query.filters.first.values).to eq ["me"]
        filters.expect_filter_by("CF user", "is (OR)", "me", cf_accessor_frontend)

        # Revisit query
        wp_table.visit_query query
        wp_table.ensure_work_package_not_listed!(wp_user)
        wp_table.expect_work_package_listed(wp_admin)

        filters.open
        filters.expect_filter_by("CF user", "is (OR)", "me", cf_accessor_frontend)
      end
    end
  end
end
