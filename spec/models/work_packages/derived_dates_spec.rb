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

RSpec.describe WorkPackage, "derived dates" do
  let(:work_package) do
    create(:work_package)
  end
  let(:child_work_package) do
    create(:work_package,
           project: work_package.project,
           start_date: child_start_date,
           due_date: child_due_date,
           parent: work_package)
  end
  let(:child_work_package_in_other_project) do
    create(:work_package,
           start_date: other_child_start_date,
           due_date: other_child_due_date,
           parent: work_package)
  end
  let(:child_start_date) { Date.today - 4.days }
  let(:child_due_date) { Date.today + 6.days }
  let(:other_child_start_date) { Date.today + 4.days }
  let(:other_child_due_date) { Date.today + 10.days }

  let(:work_packages) { [work_package, child_work_package, child_work_package_in_other_project] }

  let(:role) do
    build(:project_role,
          permissions: %i[view_work_packages])
  end
  let(:user) do
    create(:user,
           member_with_roles: { work_package.project => role })
  end

  before do
    login_as user
    work_packages
  end

  shared_examples_for "derived dates" do
    context "with all dates being set" do
      it "the derived_start_date is the minimum of both start and due date" do
        expect(subject.derived_start_date).to eql child_start_date
      end

      it "the derived_due_date is the maximum of both start and due date" do
        expect(subject.derived_due_date).to eql other_child_due_date
      end
    end

    context "with the due dates being minimal (start date being nil)" do
      let(:child_start_date) { nil }
      let(:other_child_start_date) { nil }

      it "the derived_start_date is the minimum of the due dates" do
        expect(subject.derived_start_date).to eql child_due_date
      end

      it "the derived_due_date is the maximum of the due dates" do
        expect(subject.derived_due_date).to eql other_child_due_date
      end
    end

    context "with the start date being maximum (due date being nil)" do
      let(:child_due_date) { nil }
      let(:other_child_due_date) { nil }

      it "the derived_start_date is the minimum of the start dates" do
        expect(subject.derived_start_date).to eql child_start_date
      end

      it "has the derived_due_date is the maximum of the start dates" do
        expect(subject.derived_due_date).to eql other_child_start_date
      end
    end

    context "with child dates being nil" do
      let(:child_start_date) { nil }
      let(:child_due_date) { nil }
      let(:other_child_start_date) { nil }
      let(:other_child_due_date) { nil }

      it "is nil" do
        expect(subject.derived_start_date).to be_nil
      end
    end

    context "without children" do
      let(:work_packages) { [work_package] }

      it "is nil" do
        expect(subject.derived_start_date).to be_nil
      end
    end
  end

  context "for a work_package loaded individually" do
    subject { work_package }

    it_behaves_like "derived dates"
  end

  context "for a work package that had derived dates loaded" do
    subject { WorkPackage.include_derived_dates.first }

    it_behaves_like "derived dates"
  end

  context "for an unpersisted work_package" do
    let(:work_package) { WorkPackage.new }
    let(:work_packages) { [] }

    subject { work_package }

    it "the derived_start_date is nil" do
      expect(subject.derived_start_date).to be_nil
    end

    it "the derived_due_date is nil" do
      expect(subject.derived_due_date).to be_nil
    end
  end
end
