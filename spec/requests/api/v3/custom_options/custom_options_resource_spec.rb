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
require "rack/test"

RSpec.describe "API v3 Custom Options resource", :aggregate_failures do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project) }
  let(:user) do
    create(:user, member_with_roles: { project => role })
  end
  let(:role) { create(:project_role, permissions:) }

  let(:modification) { nil }

  subject(:response) { last_response }

  describe "GET api/v3/custom_options/:id" do
    let(:path) { api_v3_paths.custom_option custom_option.id }

    before do
      modification&.call
      allow(User)
        .to receive(:current)
              .and_return(user)
      get path
    end

    describe "WorkPackageCustomField" do
      shared_let(:custom_field) do
        cf = create(:list_wp_custom_field)

        project.work_package_custom_fields << cf

        cf
      end
      shared_let(:custom_option) do
        create(:custom_option,
               custom_field:)
      end

      context "when being allowed" do
        let(:permissions) { [:view_work_packages] }

        it "is successful" do
          expect(subject.status)
            .to be(200)

          expect(response.body)
            .to be_json_eql("CustomOption".to_json)
                  .at_path("_type")

          expect(response.body)
            .to be_json_eql(custom_option.id.to_json)
                  .at_path("id")

          expect(response.body)
            .to be_json_eql(custom_option.value.to_json)
                  .at_path("value")
        end
      end

      context "when lacking permission" do
        let(:permissions) { [] }

        it "is 404" do
          expect(subject.status)
            .to be(404)
        end
      end

      context "when custom option not in project" do
        let(:permissions) { [:view_work_packages] }
        let(:modification) do
          -> do
            project.work_package_custom_fields = []
            project.save!
          end
        end

        it "is 404" do
          expect(subject.status)
            .to be(404)
        end
      end
    end

    describe "ProjectCustomField" do
      shared_let(:custom_field) { create(:list_project_custom_field) }
      shared_let(:custom_option) { create(:custom_option, custom_field:) }

      context "when being allowed" do
        let(:permissions) { [:view_project] }

        it "is successful" do
          expect(subject.status)
            .to be(200)

          expect(response.body)
            .to be_json_eql("CustomOption".to_json)
                  .at_path("_type")

          expect(response.body)
            .to be_json_eql(custom_option.id.to_json)
                  .at_path("id")

          expect(response.body)
            .to be_json_eql(custom_option.value.to_json)
                  .at_path("value")
        end
      end

      context "when lacking permission" do
        let(:user) { User.anonymous }
        let(:permissions) { [] }

        context "when login_required", with_settings: { login_required: true } do
          it_behaves_like "error response",
                          401,
                          "Unauthenticated",
                          I18n.t("api_v3.errors.code_401")
        end

        context "when not login_required", with_settings: { login_required: false } do
          it "is 404" do
            expect(subject.status)
              .to be(404)
          end
        end
      end
    end

    describe "TimeEntryCustomField" do
      shared_let(:custom_field) { create(:time_entry_custom_field, :list) }
      shared_let(:custom_option) { create(:custom_option, custom_field:) }

      context "when being allowed with log_time" do
        let(:permissions) { [:log_time] }

        it "is successful" do
          expect(subject.status)
            .to be(200)

          expect(response.body)
            .to be_json_eql("CustomOption".to_json)
                  .at_path("_type")

          expect(response.body)
            .to be_json_eql(custom_option.id.to_json)
                  .at_path("id")

          expect(response.body)
            .to be_json_eql(custom_option.value.to_json)
                  .at_path("value")
        end
      end

      context "when being allowed with log_own_time" do
        let(:permissions) { [:log_own_time] }

        it "is successful" do
          expect(subject.status)
            .to be(200)
        end
      end

      context "when lacking permission" do
        let(:user) { User.anonymous }
        let(:permissions) { [] }

        it_behaves_like "not found response based on login_required"
      end
    end

    describe "UserCustomField" do
      shared_let(:custom_field) { create(:user_custom_field, :list) }
      shared_let(:custom_option) { create(:custom_option, custom_field:) }
      let(:permissions) { [] }

      it "is successful" do
        expect(subject.status)
          .to be(200)
      end
    end

    describe "GroupCustomField" do
      shared_let(:custom_field) { create(:group_custom_field, :list) }
      shared_let(:custom_option) { create(:custom_option, custom_field:) }
      let(:permissions) { [] }

      it "is successful" do
        expect(subject.status)
          .to be(200)
      end
    end

    context "when not existing" do
      let(:path) { api_v3_paths.custom_option 0 }
      let(:permissions) { [:view_work_packages] }

      it "is 404" do
        expect(subject.status)
          .to be(404)
      end
    end
  end
end
