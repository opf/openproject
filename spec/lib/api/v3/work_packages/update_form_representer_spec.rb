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

require "spec_helper"

RSpec.describe API::V3::WorkPackages::UpdateFormRepresenter do
  include API::V3::Utilities::PathHelper

  let(:errors) { [] }
  let(:representer) do
    described_class.new(work_package, current_user: user, errors:)
  end
  let(:type) { build_stubbed(:type) }
  let(:project) { work_package.project }
  let(:permissions) { %i(edit_work_packages) }
  let(:work_package) do
    build_stubbed(:work_package)
  end

  let(:user) { build_stubbed(:user) }

  before do
    mock_permissions_for(user) do |mock|
      mock.allow_in_project *permissions, project:
    end
  end

  context "generation" do
    subject(:generated) { representer.to_json }

    describe "_links" do
      it { is_expected.to have_json_path("_links") }

      it { is_expected.to have_json_path("_links/self/href") }

      describe "validate" do
        it { is_expected.to have_json_path("_links/validate/href") }

        it { is_expected.to be_json_eql(:post.to_json).at_path("_links/validate/method") }
      end

      describe "preview markup" do
        it { is_expected.to have_json_path("_links/previewMarkup/href") }

        it { is_expected.to be_json_eql(:post.to_json).at_path("_links/previewMarkup/method") }

        it "contains link to work package" do
          body = parse_json(subject)
          actual_preview_link = body["_links"]["previewMarkup"]["href"]
          expected_preview_link = api_v3_paths.render_markup link: body["_links"]["commit"]["href"]

          expect(actual_preview_link).to eq(expected_preview_link)
        end
      end

      describe "commit" do
        context "valid work package" do
          it { is_expected.to have_json_path("_links/commit/href") }

          it { is_expected.to be_json_eql(:patch.to_json).at_path("_links/commit/method") }
        end

        context "invalid work package" do
          let(:errors) { [API::Errors::Validation.new(:subject, "it is broken")] }

          it { is_expected.not_to have_json_path("_links/commit/href") }
        end

        context "user with insufficient permissions" do
          let(:permissions) { [] }

          it { is_expected.not_to have_json_path("_links/commit/href") }
        end
      end
    end
  end
end
