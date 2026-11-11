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

RSpec.describe WorkPackage::Exports::Formatters::Id do
  it { expect(described_class.apply?(:id, :csv)).to be(true) }
  it { expect(described_class.apply?(:id, :md)).to be(true) }
  it { expect(described_class.apply?(:id, :pdf)).to be(false) }
  it { expect(described_class.apply?(:subject, :md)).to be(false) }

  it "resolves for :md through the registry" do
    expect(Exports::Register.formatter_for(WorkPackage, :id, :md)).to be_a(described_class)
  end

  it "prints the display id" do
    work_package = build_stubbed(:work_package)
    expect(described_class.new(:id).format(work_package)).to eq(work_package.display_id.to_s)
  end
end
