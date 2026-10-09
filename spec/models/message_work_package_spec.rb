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

RSpec.describe MessageWorkPackage do
  shared_let(:forum) { create(:forum) }
  shared_let(:topic) { create(:message, forum:) }
  shared_let(:work_package) { create(:work_package, project: forum.project) }

  it "links a message to the work packages created from it" do
    described_class.create!(message: topic, work_package:)

    expect(topic.created_work_packages).to contain_exactly(work_package)
  end

  it "gives a work package a single originating message" do
    described_class.create!(message: topic, work_package:)
    other = create(:message, forum:)

    expect { described_class.create!(message: other, work_package:) }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "goes away with its message, keeping the work package", :aggregate_failures do
    described_class.create!(message: topic, work_package:)

    topic.destroy

    expect(described_class.count).to eq(0)
    expect(WorkPackage.exists?(work_package.id)).to be(true)
  end

  it "goes away with its work package" do
    described_class.create!(message: topic, work_package:)

    work_package.destroy

    expect(described_class.count).to eq(0)
  end
end
