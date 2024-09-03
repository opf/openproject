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

RSpec.describe Views::UpdateContract do
  # TODO: this is just a stub to ensure that the type is not altered
  it_behaves_like "view contract" do
    let(:view) do
      build_stubbed(:view_work_packages_table).tap do |view|
        view.type = view_type if defined?(view_type)
        view.query = view_query
      end
    end

    subject(:contract) do
      described_class.new(view, current_user)
    end

    describe "validation" do
      context "with the type being changed" do
        let(:view_type) { "team_planner" }

        it_behaves_like "contract is invalid", type: %i[error_readonly]
      end
    end
  end
end
