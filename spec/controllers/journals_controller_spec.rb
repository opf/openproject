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

RSpec.describe JournalsController do
  shared_let(:project) { create(:project_with_types) }
  shared_let(:user) { create(:user, member_with_permissions: { project => [:view_work_packages] }) }

  current_user { user }
  subject(:response) do
    get :diff,
        xhr: true,
        params:
  end

  describe "GET diff" do
    render_views

    shared_examples "the diff is shown" do |value|
      it { expect(response).to have_http_status(:ok) }

      it "presents the diff correctly" do
        expect(response.body.strip).to be_html_eql <<-HTML
          <div class="text-diff">
            <label class="sr-only">Begin of the insertion</label>
            <ins class="diffmod">#{value}</ins>
            <label class="sr-only">End of the insertion</label>
          </div>
        HTML
      end
    end

    context "for work package description" do
      shared_let(:work_package) do
        create(:work_package, type: project.types.first,
                              author: user,
                              project:,
                              description: "")
      end
      let(:params) { { id: work_package.last_journal.id.to_s, field: :description, format: "js" } }

      before do
        work_package.update_attribute :description, "description\nmore changes"
      end

      describe "with a user having :view_work_package permission" do
        include_examples "the diff is shown", "description<br/>more changes"
      end

      describe "with a user not having the :view_work_package permission" do
        let(:user) { build_stubbed(:user) }

        it { expect(response).to have_http_status(:forbidden) }
      end

      describe "with a restricted/internal journal" do
        before do
          work_package.last_journal.update_columns(restricted: true)
        end

        describe "with a user having :view_work_packages but no :view_internal_comments" do
          it { expect(response).to have_http_status(:forbidden) }
        end

        describe "with a user also having :view_internal_comments" do
          let(:user) do
            create(:user, member_with_permissions: { project => %i[view_work_packages view_internal_comments] })
          end

          include_examples "the diff is shown", "description<br/>more changes"
        end
      end
    end

    context "for work package not visible to the current user" do
      shared_let(:private_project) { create(:project_with_types) }
      shared_let(:visible_work_package) do
        create(:work_package, type: private_project.types.first, project: private_project)
      end
      shared_let(:hidden_work_package) do
        create(:work_package, type: private_project.types.first, project: private_project, description: "")
      end
      shared_let(:wp_role) { create(:view_work_package_role) }
      shared_let(:shared_user) do
        create(:user).tap do |u|
          create(:member, project: private_project, entity: visible_work_package, principal: u, roles: [wp_role])
        end
      end

      before do
        hidden_work_package.update_attribute(:description, "hidden content")
      end

      let(:user) { shared_user }
      let(:params) { { id: hidden_work_package.last_journal.id.to_s, field: :description, format: "js" } }

      describe "with a user having access only to a different work package in the same project" do
        it { expect(response).to have_http_status(:forbidden) }
      end
    end

    context "for work package custom field" do
      shared_let(:type) { project.types.first }
      shared_let(:work_package) do
        create(:work_package, type:,
                              author: user,
                              project:)
      end

      let!(:custom_field) do
        create(factory_name).tap do |custom_field|
          project.work_package_custom_fields << custom_field
          type.custom_fields << custom_field
        end
      end

      let(:params) { { id: work_package.last_journal.id.to_s, field: "custom_fields_#{custom_field.id}", format: "js" } }

      before do
        work_package.update custom_field.attribute_name => "foo"
      end

      context "with format text" do
        let(:factory_name) { :text_wp_custom_field }

        describe "with a user having :view_work_package permission" do
          include_examples "the diff is shown", "foo"

          context "when field gets deleted" do
            before { custom_field.destroy }

            include_examples "the diff is shown", "foo"
          end
        end

        describe "with a user not having the :view_work_package permission" do
          let(:user) { build_stubbed(:user) }

          it { expect(response).to have_http_status(:forbidden) }
        end
      end

      context "with format string" do
        let(:factory_name) { :string_wp_custom_field }

        it { expect(response).to have_http_status(:not_found) }

        context "when field gets deleted (and we loose format information)" do
          before { custom_field.destroy }

          include_examples "the diff is shown", "foo"
        end
      end
    end

    context "for project custom field" do
      let(:params) { { id: project.last_journal.id.to_s, field: "custom_fields_#{custom_field.id}", format: "js" } }
      let(:custom_field) { create(factory_name, admin_only:, projects: [project]) }

      before do
        project.update custom_field.attribute_name => "bar"
      end

      context "with format text" do
        let(:factory_name) { :text_project_custom_field }

        context "when visible to everyone" do
          let(:admin_only) { false }
          let(:user) { create(:user, member_with_permissions: { project => %i[view_project_attributes] }) }

          describe "with a user having :view_project_attributes" do
            include_examples "the diff is shown", "bar"

            context "when field gets deleted" do
              before { custom_field.destroy }

              it { expect(response).to have_http_status(:forbidden) }
            end
          end

          describe "with a user lacking :view_project_attributes" do
            let(:user) { create(:user, member_with_permissions: { project => %i[view_project] }) }

            it { expect(response).to have_http_status(:forbidden) }
          end

          describe "with a user not being project member" do
            let(:user) { build_stubbed(:user) }

            it { expect(response).to have_http_status(:forbidden) }

            context "when field gets deleted" do
              before { custom_field.destroy }

              it { expect(response).to have_http_status(:forbidden) }
            end
          end

          describe "with an admin user" do
            let(:user) { build_stubbed(:admin) }

            include_examples "the diff is shown", "bar"

            context "when field gets deleted" do
              before { custom_field.destroy }

              # this should be 200, see https://community.openproject.org/wp/72230
              it { expect(response).to have_http_status(:bad_request) }
            end
          end
        end

        context "when admin only" do
          let(:admin_only) { true }

          describe "with a user being a project member" do
            it { expect(response).to have_http_status(:forbidden) }

            context "when field gets deleted (and we loose format information, but also admin_only mark)" do
              before { custom_field.destroy }

              it { expect(response).to have_http_status(:forbidden) }
            end
          end

          describe "with an admin user" do
            let(:user) { build_stubbed(:admin) }

            include_examples "the diff is shown", "bar"

            context "when field gets deleted (and we loose format information)" do
              before { custom_field.destroy }

              # this should be 200, see https://community.openproject.org/wp/72230
              it { expect(response).to have_http_status(:bad_request) }
            end
          end
        end
      end

      context "with format string" do
        let(:factory_name) { :string_project_custom_field }
        let(:admin_only) { false }
        let(:user) { create(:user, member_with_permissions: { project => %i[view_project_attributes] }) }

        it { expect(response).to have_http_status(:not_found) }
      end
    end

    context "for project custom comment" do
      let(:params) { { id: project.last_journal.id.to_s, field: "custom_comment_#{custom_field.id}", format: "js" } }
      let(:custom_field) { create(:string_project_custom_field, :has_comment, admin_only:, projects: [project]) }

      before do
        project.update custom_field.comment_attribute_name => "baz"
      end

      context "when visible to everyone" do
        let(:admin_only) { false }
        let(:user) { create(:user, member_with_permissions: { project => %i[view_project_attributes] }) }

        describe "with a user having :view_project_attributes" do
          include_examples "the diff is shown", "baz"

          context "when field gets deleted" do
            before { custom_field.destroy }

            it { expect(response).to have_http_status(:forbidden) }
          end
        end

        describe "with a user lacking :view_project_attributes" do
          let(:user) { create(:user, member_with_permissions: { project => %i[view_project] }) }

          it { expect(response).to have_http_status(:forbidden) }
        end

        describe "with a user not being project member" do
          let(:user) { build_stubbed(:user) }

          it { expect(response).to have_http_status(:forbidden) }

          context "when field gets deleted" do
            before { custom_field.destroy }

            it { expect(response).to have_http_status(:forbidden) }
          end
        end

        describe "with an admin user" do
          let(:user) { build_stubbed(:admin) }

          include_examples "the diff is shown", "baz"

          context "when field gets deleted" do
            before { custom_field.destroy }

            include_examples "the diff is shown", "baz"
          end
        end
      end

      context "when admin only" do
        let(:admin_only) { true }

        describe "with a user being a project member" do
          it { expect(response).to have_http_status(:forbidden) }

          context "when field gets deleted (and we loose admin_only mark)" do
            before { custom_field.destroy }

            it { expect(response).to have_http_status(:forbidden) }
          end
        end

        describe "with an admin user" do
          let(:user) { build_stubbed(:admin) }

          include_examples "the diff is shown", "baz"

          context "when field gets deleted (and we loose format information)" do
            before { custom_field.destroy }

            include_examples "the diff is shown", "baz"
          end
        end
      end
    end

    context "for project description" do
      let(:params) { { id: project.last_journal.id.to_s, field: :description, format: "js" } }

      before do
        project.update_attribute :description, "description"
      end

      describe "with a user being member of the project" do
        include_examples "the diff is shown", "description"
      end

      describe "with a user not being member of the project" do
        let(:user) { build_stubbed(:user) }

        it { expect(response).to have_http_status(:forbidden) }
      end

      describe 'when "Work Package Tracking" module is disabled' do
        before do
          project.enabled_module_names -= ["work_package_tracking"]
        end

        it { expect(response).to have_http_status(:ok) }
      end

      describe "when project is archived" do
        before do
          project.update(active: false)
        end

        it { expect(response).to have_http_status(:forbidden) }
      end
    end

    context "for another field than description" do
      shared_let(:work_package) do
        create(:work_package, type: project.types.first,
                              author: user,
                              project:)
      end

      let(:params) { { id: work_package.last_journal.id.to_s, field: :another_field, format: "js" } }

      it { expect(response).to have_http_status(:not_found) }
    end

    context "for other types, like forum message" do
      shared_let(:forum) { create(:forum, project:) }
      shared_let(:message) { create(:message, forum:, content: "initial content") }

      let(:params) { { id: message.last_journal.id.to_s, field: :description, format: "js" } }

      before do
        message.update_attribute :content, "initial content updated"
      end

      describe "even with a user having all permissions" do
        let(:user) { build_stubbed(:admin) }

        it { expect(response).to have_http_status(:bad_request) }
      end
    end

    context "for an import journal with a description diff" do
      shared_let(:work_package) do
        create(:work_package, type: project.types.first, author: user, project:, description: "")
      end

      shared_let(:import_journal) do
        cause = Journal::CausedByImport.new(
          author_name: "Imported User",
          history: [{ "field" => "description", "fromString" => "old text", "toString" => "new text" }]
        )
        work_package.add_journal(user: User.system, notes: "", cause:)
        work_package.save_journals
        work_package.last_journal
      end

      let(:params) { { id: import_journal.id.to_s, field: :description, format: "js" } }

      describe "with a user having :view_work_packages permission" do
        it { expect(response).to have_http_status(:ok) }

        it "presents the diff of the imported description" do
          # The diff is word-level, so "old" and "new" appear in separate <ins>/<del> spans
          expect(response.body).to include("text-diff")
          expect(response.body).to include("old")
          expect(response.body).to include("new")
        end
      end

      describe "with a user without permission" do
        let(:user) { build_stubbed(:user) }

        it { expect(response).to have_http_status(:forbidden) }
      end
    end

    context "for an import journal where the description was set (no previous value)" do
      shared_let(:work_package) do
        create(:work_package, type: project.types.first, author: user, project:, description: "")
      end

      shared_let(:import_journal) do
        cause = Journal::CausedByImport.new(
          author_name: "Imported User",
          history: [{ "field" => "description", "fromString" => nil, "toString" => "first description" }]
        )
        work_package.add_journal(user: User.system, notes: "", cause:)
        work_package.save_journals
        work_package.last_journal
      end

      let(:params) { { id: import_journal.id.to_s, field: :description, format: "js" } }

      it { expect(response).to have_http_status(:ok) }

      it "presents the diff with the new value" do
        expect(response.body).to include("first description")
      end
    end

    context "for an import journal with a non-description field change" do
      shared_let(:work_package) do
        create(:work_package, type: project.types.first, author: user, project:)
      end

      shared_let(:import_journal) do
        cause = Journal::CausedByImport.new(
          author_name: "Imported User",
          history: [{ "field" => "status", "fromString" => "Open", "toString" => "Closed" }]
        )
        work_package.add_journal(user: User.system, notes: "", cause:)
        work_package.save_journals
        work_package.last_journal
      end

      let(:params) { { id: import_journal.id.to_s, field: :description, format: "js" } }

      it "returns 400 because no diffable description value exists" do
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "for an import journal when the field param does not match any import item" do
      shared_let(:work_package) do
        create(:work_package, type: project.types.first, author: user, project:)
      end

      shared_let(:import_journal) do
        cause = Journal::CausedByImport.new(
          author_name: "Imported User",
          history: [{ "field" => "description", "fromString" => "a", "toString" => "b" }]
        )
        work_package.add_journal(user: User.system, notes: "", cause:)
        work_package.save_journals
        work_package.last_journal
      end

      let(:params) { { id: import_journal.id.to_s, field: :status_explanation, format: "js" } }

      it "returns 400 when the field is valid for diffing but has no matching import item" do
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
