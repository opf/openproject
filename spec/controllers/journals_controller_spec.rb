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

    context "for work package description" do
      shared_let(:work_package) do
        create(:work_package, type: project.types.first,
                              author: user,
                              project:,
                              description: "")
      end
      let(:params) { { id: work_package.last_journal.id.to_s, field: :description, format: "js" } }

      before do
        work_package.update_attribute :description, "description"
      end

      describe "with a user having :view_work_package permission" do
        it { expect(response).to have_http_status(:ok) }

        it "presents the diff correctly" do
          expect(response.body.strip).to be_html_eql <<-HTML
            <div class="text-diff">
              <label class="hidden-for-sighted">Begin of the insertion</label>
              <ins class="diffmod">description</ins>
              <label class="hidden-for-sighted">End of the insertion</label>
            </div>
          HTML
        end
      end

      describe "with a user not having the :view_work_package permission" do
        before do
          RolePermission.delete_all
        end

        it { expect(response).to have_http_status(:forbidden) }
      end
    end

    context "for work package text custom field" do
      shared_let(:type) { project.types.first }

      shared_let(:custom_field) do
        create(:text_wp_custom_field).tap do |custom_field|
          project.work_package_custom_fields << custom_field
          type.custom_fields << custom_field
        end
      end

      shared_let(:work_package) do
        create(:work_package, type:,
                              author: user,
                              project:)
      end
      let(:params) { { id: work_package.last_journal.id.to_s, field: "custom_fields_#{custom_field.id}", format: "js" } }

      before do
        work_package.update custom_field_values: { custom_field.id => "foo" }
      end

      describe "with a user having :view_work_package permission" do
        it { expect(response).to have_http_status(:ok) }

        it "presents the diff correctly" do
          expect(response.body.strip).to be_html_eql <<-HTML
            <div class="text-diff">
              <label class="hidden-for-sighted">Begin of the insertion</label>
              <ins class="diffmod">foo</ins>
              <label class="hidden-for-sighted">End of the insertion</label>
            </div>
          HTML
        end
      end

      describe "with a user not having the :view_work_package permission" do
        before do
          RolePermission.delete_all
        end

        it { expect(response).to have_http_status(:forbidden) }
      end
    end

    context "for work package string custom field" do
      shared_let(:type) { project.types.first }

      shared_let(:custom_field) do
        create(:wp_custom_field).tap do |custom_field|
          project.work_package_custom_fields << custom_field
          type.custom_fields << custom_field
        end
      end

      shared_let(:work_package) do
        create(:work_package, type:,
                              author: user,
                              project:)
      end
      let(:params) { { id: work_package.last_journal.id.to_s, field: "custom_fields_#{custom_field.id}", format: "js" } }

      before do
        work_package.update custom_field_values: { custom_field.id => "foo" }
      end

      it { expect(response).to have_http_status(:not_found) }
    end

    context "for project description" do
      let(:params) { { id: project.last_journal.id.to_s, field: :description, format: "js" } }

      before do
        project.update_attribute :description, "description"
      end

      describe "with a user being member of the project" do
        it { expect(response).to have_http_status(:ok) }

        it "presents the diff correctly" do
          expect(response.body.strip).to be_html_eql <<-HTML
            <div class="text-diff">
              <label class="hidden-for-sighted">Begin of the insertion</label>
              <ins class="diffmod">description</ins>
              <label class="hidden-for-sighted">End of the insertion</label>
            </div>
          HTML
        end
      end

      describe "with a user not being member of the project" do
        before do
          Member.delete_all
        end

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
        before do
          user.update(admin: true)
        end

        it { expect(response).to have_http_status(:forbidden) }
      end
    end
  end
end
