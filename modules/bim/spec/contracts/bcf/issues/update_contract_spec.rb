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

RSpec.describe Bim::Bcf::Issues::UpdateContract do
  it_behaves_like "issues contract" do
    let(:issue) do
      build_stubbed(:bcf_issue,
                    work_package: issue_work_package).tap do |i|
        # in order to actually have something changed
        i.index = issue_index
      end
    end
    let(:permissions) { [:manage_bcf] }

    subject(:contract) { described_class.new(issue, current_user) }

    context "if work_package is altered" do
      before do
        issue.work_package = build_stubbed(:work_package)
      end

      it "is invalid" do
        expect_valid(false, work_package_id: %i(error_readonly))
      end
    end
  end
end
