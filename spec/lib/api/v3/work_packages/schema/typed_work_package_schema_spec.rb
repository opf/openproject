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

RSpec.describe API::V3::WorkPackages::Schema::TypedWorkPackageSchema,
               with_flag: { percent_complete_edition: true } do
  let(:project) { build(:project) }
  let(:type) { build(:type) }

  let(:current_user) { build_stubbed(:user) }

  subject { described_class.new(project:, type:) }

  before do
    login_as(current_user)
    mock_permissions_for(current_user, &:allow_everything)
  end

  it "has the project set" do
    expect(subject.project).to eql(project)
  end

  it "has the type set" do
    expect(subject.type).to eql(type)
  end

  it "does not know assignable statuses" do
    expect(subject.assignable_values(:status, current_user)).to be_nil
  end

  it "does not know assignable versions" do
    expect(subject.assignable_values(:version, current_user)).to be_nil
  end

  describe "#writable?" do
    it "percentage done is writable in work-based progress calculation mode",
       with_settings: { work_package_done_ratio: "field" } do
      expect(subject).to be_writable(:done_ratio)
    end

    it "percentage done is not writable in status-based progress calculation mode",
       with_settings: { work_package_done_ratio: "status" } do
      expect(subject).not_to be_writable(:done_ratio)
    end

    it "work is writable" do
      expect(subject).to be_writable(:estimated_hours)
    end

    it "remaining work is writable" do
      expect(subject).to be_writable(:remaining_hours)
    end

    it "start date is writable" do
      expect(subject).to be_writable(:start_date)
    end

    it "finish date is writable" do
      expect(subject).to be_writable(:due_date)
    end
  end

  describe "#milestone?" do
    before do
      allow(type)
        .to receive(:is_milestone?)
              .and_return(true)
    end

    it "is the value the type has" do
      expect(subject).to be_milestone

      allow(type)
        .to receive(:is_milestone?)
        .and_return(false)

      expect(subject).not_to be_milestone
    end

    it "has a writable date" do
      expect(subject).to be_writable(:date)
    end
  end

  describe "#assignable_custom_field_values" do
    let(:list_cf) { build_stubbed(:list_wp_custom_field) }
    let(:version_cf) { build_stubbed(:version_wp_custom_field) }

    it "is nil for a list cf" do
      expect(subject.assignable_custom_field_values(list_cf)).to be_nil
    end

    it "is nil for a version cf" do
      expect(subject.assignable_custom_field_values(version_cf)).to be_nil
    end
  end
end
