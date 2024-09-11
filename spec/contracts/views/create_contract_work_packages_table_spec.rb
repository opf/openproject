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
require_relative "shared_contract_examples"

RSpec.describe Views::CreateContract do
  it_behaves_like "view contract" do
    let(:view) do
      View.new(query: view_query,
               type: view_type)
    end
    let(:view_type) do
      "work_packages_table"
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

      context "with a work_packages_calendar view with the user having the permission to view_calendar" do
        let(:permissions) { %i[view_work_packages save_queries view_calendar] }
        let(:view_type) { "work_packages_calendar" }

        it_behaves_like "contract is valid"
      end

      context "with a work_packages_calendar view with the user not having the permission to view_calendar" do
        let(:permissions) { %i[view_work_packages save_queries] }
        let(:view_type) { "work_packages_calendar" }

        it_behaves_like "contract is invalid", base: :error_unauthorized
      end
    end
  end
end
