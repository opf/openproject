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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Backlogs::WorkPackages::MenuParamsContract, type: :model do
  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:user) }

  def contract(ids:, invoker_id: ids.first)
    described_class.new(project, user, params: { ids:, invoker_id: })
  end

  it "accepts more ids than the batch cap" do
    ids = Array.new(Backlogs::WorkPackages::BatchUpdateService::MAX_BATCH_SIZE + 1) { |i| (i + 1).to_s }

    expect(contract(ids:)).to be_valid
  end

  it "rejects an invoker outside ids", :aggregate_failures do
    menu_contract = contract(ids: %w[1 2], invoker_id: "3")

    expect(menu_contract).not_to be_valid
    expect(project.errors).to be_empty
  end

  it "rejects a missing invoker" do
    expect(contract(ids: %w[1], invoker_id: nil)).not_to be_valid
  end

  [[], [""], %w[1 1]].each do |ids|
    it "rejects invalid membership of size #{ids.size}" do
      expect(contract(ids:, invoker_id: "1")).not_to be_valid
    end
  end
end
