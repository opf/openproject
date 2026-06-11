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
require "services/base_services/behaves_like_create_service"

RSpec.describe Bim::Bcf::Issues::CreateService, type: :model do
  it_behaves_like "BaseServices create service" do
    let(:model_class) { Bim::Bcf::Issue }
    let(:factory) { :bcf_issue }
    let(:work_package) { build_stubbed(:work_package) }
    let(:wp_call) { ServiceResult.success(result: work_package) }

    before do
      allow(instance)
        .to(receive(:create_work_package))
        .and_return(wp_call)
    end

    context "when WP service call fails" do
      let(:wp_call) { ServiceResult.failure(result: work_package) }

      it "returns with that call immediately" do
        expect(subject).to eq wp_call
      end
    end
  end

  describe "resolving work packages from reference_links" do
    include API::V3::Utilities::PathHelper

    let(:project) { create(:project, enabled_module_names: %i[bim work_package_tracking]) }
    let(:user) do
      create(:user,
             member_with_permissions: { project => %i[manage_bcf
                                                      view_linked_issues
                                                      view_work_packages
                                                      edit_work_packages] })
    end
    let(:work_package) { create(:work_package, project:) }
    let(:instance) { described_class.new(user:) }

    subject(:service_call) { instance.call(reference_links:) }

    context "with a link containing the numeric id" do
      let(:reference_links) { [api_v3_paths.work_package(work_package.id)] }

      it "links the topic to the referenced work package" do
        expect(service_call).to be_success
        expect(service_call.result.work_package).to eq work_package
      end
    end

    context "with semantic work package identifiers",
            with_settings: { work_packages_identifier: "semantic" } do
      let(:project) { create(:project, identifier: "SEMID", enabled_module_names: %i[bim work_package_tracking]) }

      context "with a link containing the semantic identifier" do
        let(:reference_links) { [api_v3_paths.work_package(work_package.display_id)] }

        it "links the topic to the referenced work package" do
          expect(work_package.display_id).to start_with "SEMID-"
          expect(service_call).to be_success
          expect(service_call.result.work_package).to eq work_package
        end
      end

      context "with a link containing the numeric id" do
        let(:reference_links) { [api_v3_paths.work_package(work_package.id)] }

        it "links the topic to the referenced work package" do
          expect(service_call).to be_success
          expect(service_call.result.work_package).to eq work_package
        end
      end

      context "with a link to an unknown semantic identifier" do
        let(:reference_links) { [api_v3_paths.work_package("SEMID-9999")] }

        it "fails with a not found error" do
          expect(service_call).to be_failure
          expect(service_call.errors.symbols_for(:base)).to include :error_not_found
        end
      end
    end
  end
end
