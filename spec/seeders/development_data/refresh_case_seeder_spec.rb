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

RSpec.describe DevelopmentData::RefreshCaseSeeder do
  subject(:seeder) { described_class.new(seed_data) }

  let(:work_package) { create(:work_package, subject: "Organize open source conference") }
  let(:olga) { create(:user, firstname: "Olga", lastname: "Ops") }
  let(:adam) { create(:user, firstname: "Adam", lastname: "Admin") }
  let(:high) { create(:priority_high) }
  let(:bug) { create(:type_bug) }
  let(:seed_data) do
    Source::SeedData.new(data_hash).tap do |data|
      data.store_reference(:conference, work_package)
      data.store_reference(:user__olga_ops, olga)
      data.store_reference(:user__adam_admin, adam)
      data.store_reference(:default_priority_high, high)
      data.store_reference(:default_type_bug, bug)
      data.store_reference(:default_status_new, create(:default_status))
    end
  end
  let(:data_hash) do
    YAML.load <<~SEEDING_DATA_YAML
      ai_refresh_case:
        work_package: :conference
        subject: Community Days 2023
        priority: :default_priority_high
        responsible: :user__adam_admin
        description: It moves to November.
        comments:
          - author: :user__olga_ops
            notes: The venue moved the date.
          - author: :user__olga_ops
            notes: Wanda is accountable now.
        children:
          - subject: unrelated bug
            type: :default_type_bug
    SEEDING_DATA_YAML
  end

  it "updates the work package, adds the comments by their authors, and adds the child" do
    seeder.seed!

    expect(work_package.reload).to have_attributes(subject: "Community Days 2023", description: "It moves to November.",
                                                   priority: high, responsible: adam)
    comments = work_package.journals.where.not(notes: [nil, ""]).order(:version)
    expect(comments.map { [it.user, it.notes] }).to eq([[olga, "The venue moved the date."], [olga, "Wanda is accountable now."]])
    expect(work_package.children.map { [it.subject, it.type] }).to eq([["unrelated bug", bug]])
  end

  it "does not seed a second time" do
    seeder.seed!

    expect(described_class.new(seed_data)).not_to be_applicable
  end
end
