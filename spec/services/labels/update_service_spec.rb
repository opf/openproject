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

RSpec.describe Labels::UpdateService, type: :model do
  shared_let(:admin) { create(:admin) }
  let(:label) { create(:label, name: "Bug") }
  let(:instance) { described_class.new(user: admin, model: label) }

  it "renames the label" do
    result = instance.call(name: "Defect")

    expect(result).to be_success
    expect(label.reload.name).to eq("Defect")
  end

  context "when the new name is already taken in a different case" do
    before { create(:label, name: "defect") }

    it "fails with a taken error and does not persist the change" do
      result = instance.call(name: "Defect")

      expect(result).to be_failure
      expect(result.errors.symbols_for(:name)).to include(:taken)
      expect(label.reload.name).to eq("Bug")
    end
  end

  context "with a non-admin user" do
    let(:instance) { described_class.new(user: create(:user), model: label) }

    it "is unauthorized" do
      result = instance.call(name: "Defect")

      expect(result).to be_failure
      expect(result.errors.symbols_for(:base)).to include(:error_unauthorized)
      expect(label.reload.name).to eq("Bug")
    end
  end
end
