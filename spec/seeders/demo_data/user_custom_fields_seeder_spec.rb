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

RSpec.describe DemoData::UserCustomFieldsSeeder do
  subject(:seeder) { described_class.new }

  # The default user custom field section is seeded as basic data; provide one here.
  shared_let(:section) { create(:user_custom_field_section) }

  it "creates the four demo user custom fields" do
    seeder.seed!

    expect(UserCustomField.pluck(:name))
      .to include("Job title", "Spoken languages", "Key skills", "Job start date")
    expect(UserCustomField.where.not(custom_field_section_id: nil).count).to eq(4)
  end

  it "creates Job title as a non-editable single-value list carrying the job_title semantic key" do
    seeder.seed!

    job_title = UserCustomField.find_by(name: "Job title")
    expect(job_title.field_format).to eq("list")
    expect(job_title).not_to be_multi_value
    expect(job_title).not_to be_editable
    expect(job_title.semantic_key).to eq("job_title")
    expect(job_title.custom_options.pluck(:value)).to include("Project Manager", "Software Developer")
  end

  it "creates Spoken languages and Key skills as user-editable multi-value lists" do
    seeder.seed!

    %w[Spoken\ languages Key\ skills].each do |name|
      field = UserCustomField.find_by(name:)
      expect(field).to be_multi_value
      expect(field).to be_editable
    end
  end

  it "creates Job start date as a non-editable date field" do
    seeder.seed!

    job_start_date = UserCustomField.find_by(name: "Job start date")
    expect(job_start_date.field_format).to eq("date")
    expect(job_start_date).not_to be_editable
  end

  it "does not mark any of the fields as admin-only" do
    seeder.seed!

    expect(UserCustomField.where(admin_only: true)).to be_empty
  end

  context "when no user custom field section exists yet (e.g. BIM edition)" do
    before { UserCustomFieldSection.delete_all }

    it "creates a default section so the fields can be persisted" do
      expect { seeder.seed! }.to change(UserCustomFieldSection, :count).from(0).to(1)
      expect(UserCustomField.where(custom_field_section_id: nil)).to be_empty
    end
  end

  it "is idempotent" do
    seeder.seed!

    expect { described_class.new.seed! }.not_to change(UserCustomField, :count)
  end

  it "does not claim the semantic key when another field already owns it" do
    create(:user_custom_field, name: "Existing role", semantic_key: "job_title",
                               user_custom_field_section: section)

    seeder.seed!

    expect(UserCustomField.find_by(name: "Job title").semantic_key).to be_nil
  end
end
