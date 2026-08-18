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

RSpec.describe Queries::BaseQuery, "group bys" do
  current_user { create(:admin) }

  # NotificationQuery is a query class that registers group bys.
  let(:instance) { Queries::Notifications::NotificationQuery.new(user: User.current) }

  describe "#group_bys" do
    it "is empty by default" do
      expect(instance.group_bys).to eq([])
    end
  end

  describe "#group" do
    it "sets a single group by" do
      instance.group(:reason)

      expect(instance.group_bys.map(&:name)).to eq([:reason])
    end

    it "sets several group bys, keeping their order" do
      instance.group(:reason, :project)

      expect(instance.group_bys.map(&:name)).to eq(%i[reason project_id])
    end

    it "replaces previously set group bys rather than appending" do
      instance.group(:reason).group(:project)

      expect(instance.group_bys.map(&:name)).to eq([:project_id])
    end

    it "returns the query to allow chaining" do
      expect(instance.group(:reason)).to eq(instance)
    end
  end

  describe "validations" do
    it "is valid without any group by" do
      expect(instance).to be_valid
    end

    it "is valid with registered group bys" do
      instance.group(:reason, :project)

      expect(instance).to be_valid
    end

    it "is invalid with an unregistered group by" do
      instance.group(:does_not_exist)

      expect(instance).not_to be_valid
      expect(instance.errors[:group_bys]).to be_present
    end

    it "reports every invalid group by" do
      instance.group(:nope, :also_nope)
      instance.valid?

      expect(instance.errors[:group_bys].size).to eq(2)
    end
  end

  describe "#groups" do
    it "is nil without a group by" do
      expect(instance.groups).to be_nil
    end

    it "selects the group by and a count for a single group by" do
      instance.group(:reason)

      expect(instance.groups.to_sql).to include('"notifications"."reason", COUNT(*)')
    end

    it "selects every group by and a count for several group bys" do
      instance.group(:reason, :project)

      expect(instance.groups.to_sql).to include('"notifications"."reason", "project_id", COUNT(*)')
    end

    it "applies the joins of every group by" do
      instance.group(:project)

      expect(instance.groups.to_sql).to include("JOIN work_packages")
    end

    it "is an empty scope when invalid" do
      instance.group(:does_not_exist)

      expect(instance.groups.to_sql).to include("1=0").or include("1 = 0")
    end
  end

  describe "#group_values" do
    shared_let(:project) { create(:project) }
    shared_let(:work_package) { create(:work_package, project:) }

    before do
      create_list(:notification, 2, recipient: User.current, resource: work_package, reason: :mentioned)
      create(:notification, recipient: User.current, resource: work_package, reason: :assigned)
    end

    it "returns a count per value for a single group by" do
      instance.group(:reason)

      expect(instance.group_values).to eq("mentioned" => 2, "assigned" => 1)
    end

    it "returns a count per combination of values for several group bys" do
      instance.group(:reason, :project)

      expect(instance.group_values).to eq(["mentioned", project.id] => 2,
                                          ["assigned", project.id] => 1)
    end
  end

  # A query class that has no group bys at all - ProjectQuery does not even
  # respond to #group_bys - must still validate and order.
  describe "a query without group by support" do
    let(:instance) { ProjectQuery.new(name: "Projects") }

    it "does not respond to group_bys" do
      expect(instance).not_to respond_to(:group_bys)
    end

    it "is valid" do
      expect(instance).to be_valid
    end

    it "still builds results" do
      expect(instance.results.to_sql).to be_present
    end
  end
end
