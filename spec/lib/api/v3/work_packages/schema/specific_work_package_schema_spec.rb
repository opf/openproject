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

RSpec.describe API::V3::WorkPackages::Schema::SpecificWorkPackageSchema,
               with_flag: { percent_complete_edition: true } do
  let(:project) { build_stubbed(:project) }
  let(:type) { build_stubbed(:type) }
  let(:work_package) do
    build_stubbed(:work_package,
                  project:,
                  type:)
  end
  let(:current_user) { build_stubbed(:user) }

  before do
    mock_permissions_for(current_user, &:allow_everything)
    login_as(current_user)
  end

  subject { described_class.new(work_package:) }

  it "has the project set" do
    expect(subject.project).to eql(project)
  end

  it "has the type set" do
    expect(subject.type).to eql(type)
  end

  it "has an id" do
    expect(subject.id).to eql(work_package.id)
  end

  describe "#milestone?" do
    it "shows the work_package's value" do
      allow(work_package)
        .to receive(:milestone?)
        .and_return(true)

      expect(subject).to be_milestone

      allow(work_package)
        .to receive(:milestone?)
        .and_return(false)

      expect(subject).not_to be_milestone
    end
  end

  describe "#readonly?" do
    it "modifies the writable attributes" do
      allow(work_package)
        .to receive(:readonly_status?)
        .and_return(true)

      expect(subject).to be_readonly
      expect(subject).to be_writable("status")
      expect(subject).not_to be_writable("subject")

      allow(work_package)
        .to receive(:readonly_status?)
        .and_return(false)

      # As the writability is memoized we need to have a new schema
      new_schema = described_class.new(work_package:)
      expect(new_schema).not_to be_readonly
      expect(new_schema).to be_writable("status")
      expect(new_schema).to be_writable("subject")
    end
  end

  describe "#available_custom_fields" do
    it "delegates to work_package" do
      expect(work_package)
        .to receive(:available_custom_fields)

      subject.available_custom_fields
    end
  end

  describe "#assignable_types" do
    let(:result) do
      result = double
      allow(result).to receive(:includes).and_return(result)
      result
    end

    it "calls through to the project" do
      expect(project).to receive(:types).and_return(result)
      expect(subject.assignable_values(:type, current_user)).to eql(result)
    end
  end

  describe "#assignable_versions" do
    let(:result) { double }

    it "calls through to the work package" do
      expect(work_package).to receive(:assignable_versions).and_return(result)
      expect(subject.assignable_values(:version, current_user)).to eql(result)
    end
  end

  describe "#assignable_priorities" do
    let(:active_priority) { build(:priority, active: true) }
    let(:inactive_priority) { build(:priority, active: false) }

    before do
      active_priority.save!
      inactive_priority.save!
    end

    it "returns only active priorities" do
      expect(subject.assignable_values(:priority, current_user).size).to be >= 1
      subject.assignable_values(:priority, current_user).each do |priority|
        expect(priority.active).to be_truthy
      end
    end
  end

  describe "#assignable_categories" do
    let(:category) { instance_double(Category) }

    before do
      allow(project).to receive(:categories).and_return([category])
    end

    it "returns all categories of the project" do
      expect(subject.assignable_values(:category, current_user)).to contain_exactly(category)
    end
  end

  describe "#assignable_budgets" do
    subject { described_class.new(work_package:) }

    before do
      allow(project).to receive(:budgets).and_return([instance_double(Budget)])
    end

    it "returns project.budgets" do
      expect(subject.assignable_values(:budget, nil)).to eql(project.budgets)
    end
  end

  describe "#writable?" do
    describe "% Complete" do
      it "is writable in work-based progress calculation mode",
         with_settings: { work_package_done_ratio: "field" } do
        expect(subject).to be_writable(:done_ratio)
      end

      it "is not writable in status-based progress calculation mode",
         with_settings: { work_package_done_ratio: "status" } do
        expect(subject).not_to be_writable(:done_ratio)
      end
    end

    describe "work" do
      it "is writable when the work package is a parent" do
        allow(work_package).to receive(:leaf?).and_return(false)
        expect(subject).to be_writable(:estimated_hours)
      end

      it "is writable when the work package is a leaf" do
        allow(work_package).to receive(:leaf?).and_return(true)
        expect(subject).to be_writable(:estimated_hours)
      end
    end

    describe "derived work" do
      it "is not writable when the work package is a parent" do
        allow(work_package).to receive(:leaf?).and_return(false)
        expect(subject).not_to be_writable(:derived_estimated_time)
      end

      it "is not writable when the work package is a leaf" do
        allow(work_package).to receive(:leaf?).and_return(true)
        expect(subject).not_to be_writable(:derived_estimated_time)
      end
    end

    describe "start date" do
      context "when work package is parent" do
        before do
          allow(work_package)
            .to receive(:leaf?)
            .and_return(false)
        end

        context "when scheduled automatically" do
          it "is not writable" do
            expect(subject).not_to be_writable(:start_date)
          end
        end

        context "when scheduled manually" do
          before do
            work_package.schedule_manually = true
          end

          it "is writable" do
            expect(subject).to be_writable(:start_date)
          end
        end
      end

      context "when work package is a leaf" do
        it "is writable" do
          allow(work_package).to receive(:leaf?).and_return(true)
          expect(subject).to be_writable(:start_date)
        end
      end
    end

    describe "due date" do
      context "when work package is parent" do
        before do
          allow(work_package)
            .to receive(:leaf?)
            .and_return(false)
        end

        context "when scheduled automatically" do
          it "is not writable" do
            expect(subject).not_to be_writable(:due_date)
          end
        end

        context "when scheduled manually" do
          before do
            work_package.schedule_manually = true
          end

          it "is writable" do
            expect(subject).to be_writable(:due_date)
          end
        end
      end

      context "when work package is a leaf" do
        it "is writable" do
          allow(work_package).to receive(:leaf?).and_return(true)
          expect(subject).to be_writable(:due_date)
        end
      end
    end

    describe "date" do
      # As a date only exists on milestones, which can have no children
      # we do not need to check for differences caused by scheduling modes.
      before do
        allow(work_package.type).to receive(:is_milestone?).and_return(true)
      end

      it "is not writable when the work package is a parent" do
        allow(work_package).to receive(:leaf?).and_return(false)
        expect(subject).not_to be_writable(:date)
      end

      it "is writable when the work package is a leaf" do
        allow(work_package).to receive(:leaf?).and_return(true)
        expect(subject).to be_writable(:date)
      end
    end

    describe "priority" do
      it "is writable when the work package is a parent" do
        allow(work_package).to receive(:leaf?).and_return(false)
        expect(subject).to be_writable(:priority)
      end

      it "is writable when the work package is a leaf" do
        allow(work_package).to receive(:leaf?).and_return(true)
        expect(subject).to be_writable(:priority)
      end
    end
  end

  describe "#assignable_custom_field_values" do
    let(:list_cf) { create(:list_wp_custom_field) }
    let(:version_cf) { build_stubbed(:version_wp_custom_field) }

    it "is a list custom fields' possible values" do
      expect(subject.assignable_custom_field_values(list_cf))
        .to match_array list_cf.possible_values
    end

    it "is a version custom fields' project values" do
      result = [instance_double(Version)]

      allow(work_package)
        .to receive(:assignable_versions)
        .and_return(result)

      expect(subject.assignable_custom_field_values(version_cf)).to eql result
    end
  end
end
