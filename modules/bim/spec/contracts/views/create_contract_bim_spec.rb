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
require "contracts/shared/model_contract_shared_context"
require "contracts/views/shared_contract_examples"

RSpec.describe Views::CreateContract do
  it_behaves_like "view contract", true do
    let(:view) do
      View.new(query: view_query,
               type: view_type)
    end
    let(:view_type) do
      "bim"
    end
    let(:permissions) do
      %i[view_work_packages
         view_ifc_models
         save_queries
         save_bcf_queries
         manage_public_queries
         manage_public_bcf_queries]
    end

    subject(:contract) do
      described_class.new(view, current_user)
    end

    describe "validation" do
      context "with the type being nil" do
        let(:view_type) { nil }

        it_behaves_like "contract is invalid", type: :inclusion
      end

      context "with the type not being one of the configured" do
        let(:view_type) { "blubs" }

        it_behaves_like "contract is invalid", type: :inclusion
      end

      context "without the :view_ifc_models permission" do
        let(:permissions) { %i[view_work_packages save_queries save_bcf_queries] }

        it_behaves_like "contract is invalid", base: :error_unauthorized
      end

      context "without the :save_bcf_queries permission" do
        let(:permissions) { %i[view_ifc_models view_work_packages save_queries] }

        it_behaves_like "contract is invalid", base: :error_unauthorized
      end

      context "with a public query and without the :manage_public_bcf_queries permission" do
        let(:query_public) { true }
        let(:permissions) { %i[view_ifc_models view_work_packages save_queries save_bcf_queries manage_public_queries] }

        it_behaves_like "contract is invalid", base: :error_unauthorized
      end

      context "with a public query and all necessary permissions" do
        let(:query_public) { true }

        it_behaves_like "contract is valid"
      end

      context "with a private query and all necessary permissions" do
        let(:permissions) { %i[view_work_packages view_ifc_models save_queries save_bcf_queries] }

        it_behaves_like "contract is valid"
      end
    end
  end
end
