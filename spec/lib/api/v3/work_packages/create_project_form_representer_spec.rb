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

RSpec.describe API::V3::WorkPackages::CreateProjectFormRepresenter do
  include API::V3::Utilities::PathHelper

  let(:errors) { [] }
  let(:project) { work_package.project }
  let(:permissions) { %i(edit_work_packages) }
  let(:type) { build_stubbed(:type) }
  let(:work_package) do
    build_stubbed(:work_package,
                  type:)
  end
  let(:representer) do
    described_class.new(work_package, current_user: user, errors:)
  end

  let(:user) { build_stubbed(:user) }

  before do
    mock_permissions_for(user) do |mock|
      mock.allow_in_project *permissions, project:
    end
  end

  subject(:generated) { representer.to_json }

  describe "_links" do
    it do
      expect(generated).to be_json_eql(
        api_v3_paths.create_project_work_package_form(work_package.project_id).to_json
      )
        .at_path("_links/self/href")
    end

    it do
      expect(generated).to be_json_eql(:post.to_json).at_path("_links/self/method")
    end

    describe "validate" do
      it do
        expect(generated).to be_json_eql(
          api_v3_paths.create_project_work_package_form(work_package.project_id).to_json
        )
          .at_path("_links/validate/href")
      end

      it do
        expect(generated).to be_json_eql(:post.to_json).at_path("_links/validate/method")
      end
    end

    describe "preview markup" do
      it do
        expect(generated).to be_json_eql(
          api_v3_paths.render_markup(
            link: api_v3_paths.project(work_package.project_id)
          ).to_json
        )
          .at_path("_links/previewMarkup/href")
      end

      it do
        expect(generated).to be_json_eql(:post.to_json).at_path("_links/previewMarkup/method")
      end

      it "contains link to work package" do
        expected_preview_link =
          api_v3_paths.render_markup(link: "/api/v3/projects/#{work_package.project_id}")
        expect(subject).to be_json_eql(expected_preview_link.to_json)
          .at_path("_links/previewMarkup/href")
      end
    end

    describe "commit" do
      context "with a valid work package" do
        it do
          expect(generated).to be_json_eql(
            api_v3_paths.work_packages_by_project(work_package.project_id).to_json
          )
            .at_path("_links/commit/href")
        end

        it do
          expect(generated).to be_json_eql(:post.to_json).at_path("_links/commit/method")
        end
      end

      context "with an invalid work package" do
        let(:errors) { [API::Errors::Validation.new(:subject, "it is broken")] }

        it do
          expect(generated).not_to have_json_path("_links/commit/href")
        end
      end

      context "with the user having insufficient permissions" do
        let(:permissions) { [] }

        it do
          expect(generated).not_to have_json_path("_links/commit/href")
        end
      end
    end

    describe "customFields" do
      context "with the permission to select custom fields" do
        let(:permissions) { [:select_custom_fields] }

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
      context "for an admin and with a type" do
        let(:user) { build_stubbed(:user, admin: true) }

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
        let(:type) { nil }

        let(:user) { build_stubbed(:user, admin: true) }

        it "has no link to configure the form" do
          expect(generated).not_to have_json_path("_links/configureForm")
        end
      end

      context "for a non admin" do
        it "has no link to configure the form" do
          expect(generated).not_to have_json_path("_links/configureForm")
        end
      end
    end
  end
end
