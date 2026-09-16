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

RSpec.describe WorkPackage, "labels" do
  let(:work_package) { create(:work_package) }
  let!(:lower_label) { create(:label, name: "apple") }
  let!(:higher_label) { create(:label, name: "zebra") }

  before do
    work_package.labels << higher_label
    work_package.labels << lower_label
  end

  it "returns labels in id order, also when preloaded" do
    preloaded = described_class.where(id: work_package.id).includes(:labels).first

    expect(work_package.reload.labels).to eq([lower_label, higher_label])
    expect(preloaded.labels).to eq([lower_label, higher_label])
  end

  it "deletes its labelings but keeps the labels when destroyed" do
    work_package.destroy!

    expect(Labeling.where(labelable: work_package)).not_to exist
    expect(Label.where(id: [lower_label.id, higher_label.id]).count).to eq(2)
  end

  it "drops a deleted label from its labels" do
    lower_label.destroy!

    expect(work_package.reload.labels).to eq([higher_label])
  end

  describe ".labeled_with" do
    it "returns only the work packages carrying the label" do
      other = create(:work_package)
      other.labels << lower_label
      create(:work_package)

      expect(described_class.labeled_with(lower_label)).to contain_exactly(work_package, other)
      expect(described_class.labeled_with(higher_label)).to contain_exactly(work_package)
    end
  end
end
