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
#++require 'rspec'

require "spec_helper"

RSpec.describe API::V3::WorkPackages::CreateFormRepresenter do
  include API::V3::Utilities::PathHelper

  let(:errors) { [] }
  let(:project) do
    build_stubbed(:project)
  end
  let(:work_package) do
    build_stubbed(:work_package, project:).tap do |wp|
      allow(wp).to receive(:assignable_versions).and_return []
    end
  end
  let(:current_user) do
    build_stubbed(:user)
  end
  let(:representer) do
    described_class.new(work_package, current_user:, errors:)
  end

  subject(:generated) { representer.to_json }

  describe "_links" do
    it "links to the create form api" do
      expect(generated)
        .to be_json_eql(api_v3_paths.create_work_package_form.to_json)
        .at_path("_links/self/href")
    end

    it "is a post" do
      expect(generated)
        .to be_json_eql(:post.to_json)
        .at_path("_links/self/method")
    end

    describe "validate" do
      it "links to the create form api" do
        expect(generated)
          .to be_json_eql(api_v3_paths.create_work_package_form.to_json)
          .at_path("_links/validate/href")
      end

      it "is a post" do
        expect(generated)
          .to be_json_eql(:post.to_json)
          .at_path("_links/validate/method")
      end
    end

    describe "preview markup" do
      it "links to the markup api" do
        path = api_v3_paths.render_markup(link: api_v3_paths.project(work_package.project_id))
        expect(generated)
          .to be_json_eql(path.to_json)
          .at_path("_links/previewMarkup/href")
      end

      it "is a post" do
        expect(generated)
          .to be_json_eql(:post.to_json)
          .at_path("_links/previewMarkup/method")
      end

      it "contains link to work package" do
        expected_preview_link =
          api_v3_paths.render_markup(link: "/api/v3/projects/#{work_package.project_id}")
        expect(subject)
          .to be_json_eql(expected_preview_link.to_json)
          .at_path("_links/previewMarkup/href")
      end
    end

    describe "commit" do
      before do
        mock_permissions_for(current_user) do |mock|
          mock.allow_in_project :add_work_packages, project:
        end
      end

      context "for a valid work package" do
        it "links to the work package create api" do
          expect(generated)
            .to be_json_eql(api_v3_paths.work_packages.to_json)
                  .at_path("_links/commit/href")
        end

        it "is a post" do
          expect(generated)
            .to be_json_eql(:post.to_json)
                  .at_path("_links/commit/method")
        end
      end

      context "for an invalid work package" do
        let(:errors) { [API::Errors::Validation.new(:subject, "it is broken")] }

        it "has no link" do
          expect(generated).not_to have_json_path("_links/commit/href")
        end
      end

      context "for a user with insufficient permissions" do
        before do
          mock_permissions_for(current_user, &:forbid_everything)
        end

        it "has no link" do
          expect(generated).not_to have_json_path("_links/commit/href")
        end
      end
    end

    describe "customFields" do
      before do
        mock_permissions_for(current_user, &:forbid_everything)
      end

      context "with the permission to select custom fields" do
        before do
          mock_permissions_for(current_user) do |mock|
            mock.allow_in_project :select_custom_fields, project:
          end
        end

        it "has a link to set the custom fields for that project" do
          expected = {
            href: project_settings_custom_fields_path(work_package.project),
            type: "text/html",
            title: "Custom fields"
          }

          expect(generated)
            .to be_json_eql(expected.to_json)
                  .at_path("_links/customFields")
        end
      end

      context "without the permission to select custom fields" do
        it "has no link to set the custom fields for that project" do
          expect(generated).not_to have_json_path("_links/customFields")
        end
      end
    end

    describe "configureForm" do
      before do
        mock_permissions_for(current_user, &:allow_everything)
      end

      context "for an admin and with type" do
        let(:type) { build_stubbed(:type) }
        let(:current_user) { build_stubbed(:admin) }
        let(:work_package) do
          build(:work_package,
                id: 42,
                created_at: DateTime.now,
                updated_at: DateTime.now,
                type:)
        end

        it "has a link to configure the form" do
          expected = {
            href: "/types/#{type.id}/edit?tab=form_configuration",
            type: "text/html",
            title: "Configure form"
          }

          expect(generated)
            .to be_json_eql(expected.to_json)
            .at_path("_links/configureForm")
        end
      end

      context "for an admin and without type" do
        before do
          allow(work_package).to receive(:type).and_return(nil)
          allow(work_package).to receive(:type_id).and_return(nil)
        end

        it "has no link to configure the form" do
          expect(generated).not_to have_json_path("_links/configureForm")
        end
      end

      context "for a nonadmin" do
        it "has no link to configure the form" do
          expect(generated).not_to have_json_path("_links/configureForm")
        end
      end
    end
  end
end
