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

require Rails.root.join("spec/models/enumerations/shared_enumeration_examples").to_s

RSpec.describe TimeEntryActivity do
  let(:new_activity) { described_class.new }
  let(:saved_activity) { described_class.create name: "Design" }

  it "is an enumeration" do
    expect(new_activity)
      .to be_a(Enumeration)
  end

  describe "#objects_count" do
    it "represents the count of time entries of that activity" do
      expect { create(:time_entry, activity: saved_activity) }
        .to change(saved_activity, :objects_count)
              .from(0)
              .to(1)
    end
  end

  describe "#option_name" do
    it "is enumeration_activities" do
      expect(new_activity.option_name)
        .to eq :enumeration_activities
    end
  end

  it_behaves_like "enumeration#active handling", false do
    let(:enumeration) { described_class.new(attributes_for(:time_entry_activity)) }
  end
end
