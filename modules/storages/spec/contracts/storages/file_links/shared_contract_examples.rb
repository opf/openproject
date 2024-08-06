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
require_module_spec_helper
require "contracts/shared/model_contract_shared_context"

RSpec.shared_examples_for "file_link contract" do
  include_context "ModelContract shared context"

  let(:current_user) { create(:user) }
  let(:role) { create(:project_role, permissions: [:manage_file_links]) }
  let(:project) { create(:project, members: { current_user => role }) }
  let(:work_package) { create(:work_package, project:) }
  let(:storage) { create(:nextcloud_storage) }
  let!(:project_storage) { create(:project_storage, project:, storage:) }
  let(:file_link) do
    build(:file_link, container: work_package,
                      storage:,
                      creator: file_link_creator,
                      **file_link_attributes)
  end
  let(:file_link_creator) { current_user }
  let(:file_link_attributes) { {} }

  it_behaves_like "contract is valid for active admins and invalid for regular users"

  describe "validations" do
    context "when all attributes are valid" do
      it_behaves_like "contract is valid"
    end

    describe "storage_id" do
      context "when empty" do
        let(:storage_id) { "" }
        let(:file_link) { create(:file_link, container: work_package, storage_id:) }

        include_examples "contract is invalid", storage: :blank
      end
    end

    describe "origin_id" do
      context "when empty" do
        let(:file_link_attributes) { { origin_id: "" } }

        include_examples "contract is invalid", origin_id: %i[blank too_short]
      end

      context "when nil" do
        let(:file_link_attributes) { { origin_id: nil } }

        include_examples "contract is invalid", origin_id: %i[blank too_short]
      end

      context "when numeric" do
        let(:file_link_attributes) { { origin_id: 12345 } }

        include_examples "contract is valid"
      end

      context "when uuid-like" do
        let(:file_link_attributes) { { origin_id: "5eda571a-819e-44b2-939c-2301f9322ac6" } }

        include_examples "contract is valid"
      end

      context "when having non ascii characters" do
        let(:file_link_attributes) { { origin_id: "Hëllò Wôrłd!" } }

        include_examples "contract is valid"
      end

      context "when longer than 100 characters" do
        let(:file_link_attributes) { { origin_id: "1" * 201 } }

        include_examples "contract is invalid", origin_id: :too_long
      end
    end

    describe "origin_name" do
      context "when empty" do
        let(:file_link_attributes) { { origin_name: "" } }

        include_examples "contract is invalid", origin_name: :blank
      end

      context "when nil" do
        let(:file_link_attributes) { { origin_name: nil } }

        include_examples "contract is invalid", origin_name: :blank
      end
    end

    describe "origin_mime_type" do
      context "when empty" do
        let(:file_link_attributes) { { origin_mime_type: "" } }

        include_examples "contract is valid"
      end

      context "when nil" do
        let(:file_link_attributes) { { origin_mime_type: nil } }

        include_examples "contract is valid"
      end

      context "when anything" do
        let(:file_link_attributes) { { origin_mime_type: "abcdef/zyxwvut" } }

        include_examples "contract is valid"
      end

      context "when longer than 255 characters" do
        let(:file_link_attributes) { { origin_mime_type: "a" * 256 } }

        include_examples "contract is invalid", origin_mime_type: :too_long
      end
    end

    shared_examples_for "optional attribute" do |params|
      context "when nil" do
        let(:file_link_attributes) { params.transform_values { nil } }

        include_examples "contract is valid"
      end

      context "when #{params.inspect}" do
        let(:file_link_attributes) { params }

        include_examples "contract is valid"
      end
    end

    {
      origin_created_by_name: "someone",
      origin_last_modified_by_name: "someone",
      origin_created_at: Time.zone.now,
      origin_updated_at: Time.zone.now
    }.each do |(attribute, a_valid_value)|
      describe attribute.name do
        it_behaves_like "optional attribute", attribute => a_valid_value
      end
    end
  end

  include_examples "contract reuses the model errors"
end
