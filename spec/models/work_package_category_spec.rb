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

RSpec.describe WorkPackageCategory do
  subject(:record) { described_class.new(work_package:, category:) }

  let(:work_package) { create(:work_package) }
  let(:category) { create(:category, project: work_package.project) }

  describe "associations" do
    it { is_expected.to belong_to(:work_package) }
    it { is_expected.to belong_to(:category) }
  end

  it { is_expected.to be_valid }

  it "does not allow the same category twice on a work package" do
    described_class.create!(work_package:, category:)

    expect { described_class.create!(work_package:, category:) }
      .to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "is deleted together with its category" do
    record.save!

    category.destroy

    expect(described_class.exists?(record.id)).to be false
  end
end
