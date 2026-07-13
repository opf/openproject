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

require_relative "../../spec_helper"

RSpec.describe CostQuery::Operator, :reporting_query_helper do
  minimal_query

  let!(:project1) { create(:project, name: "project1", created_at: 5.minutes.ago) }
  let!(:project2) { create(:project, name: "project2", created_at: 6.minutes.ago) }

  let(:admin) { create(:admin) }

  before do
    allow(User).to receive(:current).and_return(admin)
  end

  def cost_query(table, field, operator, *values)
    sql = CostQuery::SqlStatement.new table
    yield sql if block_given?
    operator.to_operator.modify sql, field, *values
    ActiveRecord::Base.connection.select_all(sql.to_s).to_a
  end

  def query_on_entries(field, operator, *values)
    sql = CostQuery::SqlStatement.for_entries
    operator.to_operator.modify sql, field, *values
    ActiveRecord::Base.connection.select_all(sql.to_s).to_a
  end

  def create_project(options = {})
    create(:project, options)
  end

  it "does =" do
    expect(cost_query("projects", "id", "=", project1.id).size).to eq(1)
  end

  it "does = for multiple values" do
    expect(cost_query("projects", "id", "=", project1.id, project2.id).size).to eq(2)
  end

  it "does = for no values" do
    sql = CostQuery::SqlStatement.new "projects"
    "=".to_operator.modify sql, "id"
    result = (ActiveRecord::Base.connection.select_all sql.to_s)
    expect(result).to be_empty
  end

  it "does = for nil" do
    expect(cost_query("projects", "id", "=", nil).size).to eq(0)
  end

  it "does = for empty string" do
    expect(cost_query("projects", "id", "=", "").size).to eq(0)
  end

  it "does <=" do
    expect(cost_query("projects", "id", "<=", project2.id - 1).size).to eq(1)
  end

  it "does >=" do
    expect(cost_query("projects", "id", ">=", project1.id + 1).size).to eq(1)
  end

  it "does not raise for >d with nil" do
    expect { cost_query("projects", "created_at", ">d", nil) }.not_to raise_error
  end

  it "does not raise for <d with nil" do
    expect { cost_query("projects", "created_at", "<d", nil) }.not_to raise_error
  end

  it "does not raise for =d with nil" do
    expect { cost_query("projects", "created_at", "=d", nil) }.not_to raise_error
  end

  it "does not raise for >=d with nil" do
    expect { cost_query("projects", "created_at", ">=d", nil) }.not_to raise_error
  end

  it "does !" do
    expect(cost_query("projects", "id", "!", project1.id).size).to eq(1)
  end

  it "does ! for empty string" do
    expect(cost_query("projects", "id", "!", "").size).to eq(0)
  end

  it "does ! for multiple values" do
    expect(cost_query("projects", "id", "!", project1.id, project2.id).size).to eq(0)
  end

  it "does !*" do
    expect(cost_query("cost_entries", "project_id", "!*", []).size).to eq(0)
  end

  it "does ~ (contains)" do
    expect(cost_query("projects", "name", "~", "o").size).to eq(Project.all.count { |p| p.name.include?("o") })
    expect(cost_query("projects", "name", "~", "test").size).to eq(Project.all.count { |p| p.name.include?("test") })
    expect(cost_query("projects", "name", "~", "child").size).to eq(Project.all.count { |p| p.name.include?("child") })
  end

  it "does !~ (not contains)" do
    expect(cost_query("projects", "name", "!~", "o").size).to eq(Project.all.count { |p| p.name.exclude?("o") })
    expect(cost_query("projects", "name", "!~", "test").size).to eq(Project.all.count { |p| p.name.exclude?("test") })
    expect(cost_query("projects", "name", "!~", "child").size).to eq(Project.all.count { |p| p.name.exclude?("child") })
  end

  it "does c (closed work_package)" do
    expect(cost_query("work_packages", "status_id", "c") { |s| s.join Status => [WorkPackage, :status] }.size).to be >= 0
  end

  it "does o (open work_package)" do
    expect(cost_query("work_packages", "status_id", "o") { |s| s.join Status => [WorkPackage, :status] }.size).to be >= 0
  end

  it "does give the correct number of results when counting closed and open work_packages" do
    a = cost_query("work_packages", "status_id", "o") { |s| s.join Status => [WorkPackage, :status] }.size
    b = cost_query("work_packages", "status_id", "c") { |s| s.join Status => [WorkPackage, :status] }.size
    expect(WorkPackage.count).to eq(a + b)
  end

  it "does w (this week)" do
    # somehow this test doesn't work on sundays
    n = cost_query("projects", "created_at", "w").size
    day_in_this_week = Time.zone.now.at_beginning_of_week + 1.day
    create(:project, created_at: day_in_this_week)
    expect(cost_query("projects", "created_at", "w").size).to eq(n + 1)
    create(:project, created_at: day_in_this_week + 7.days)
    create(:project, created_at: day_in_this_week - 7.days)
    expect(cost_query("projects", "created_at", "w").size).to eq(n + 1)
  end

  it "does t (today)" do
    s = cost_query("projects", "created_at", "t").size
    create(:project, created_at: Date.yesterday)
    expect(cost_query("projects", "created_at", "t").size).to eq(s)
    create(:project, created_at: Time.zone.now)
    expect(cost_query("projects", "created_at", "t").size).to eq(s + 1)
  end

  it "does <t+ (before the day which is n days in the future)" do
    n = cost_query("projects", "created_at", "<t+", 2).size
    create(:project, created_at: Date.tomorrow + 1)
    expect(cost_query("projects", "created_at", "<t+", 2).size).to eq(n + 1)
    create(:project, created_at: Date.tomorrow + 2)
    expect(cost_query("projects", "created_at", "<t+", 2).size).to eq(n + 1)
  end

  it "does t+ (n days in the future)" do
    n = cost_query("projects", "created_at", "t+", 1).size
    create(:project, created_at: Date.tomorrow)
    expect(cost_query("projects", "created_at", "t+", 1).size).to eq(n + 1)
    create(:project, created_at: Date.tomorrow + 2)
    expect(cost_query("projects", "created_at", "t+", 1).size).to eq(n + 1)
  end

  it "does >t+ (after the day which is n days in the future)" do
    n = cost_query("projects", "created_at", ">t+", 1).size
    create(:project, created_at: Time.zone.now)
    expect(cost_query("projects", "created_at", ">t+", 1).size).to eq(n)
    create(:project, created_at: Date.tomorrow + 1)
    expect(cost_query("projects", "created_at", ">t+", 1).size).to eq(n + 1)
  end

  it "does >t- (after the day which is n days ago)" do
    n = cost_query("projects", "created_at", ">t-", 1).size
    create(:project, created_at: Time.zone.today)
    expect(cost_query("projects", "created_at", ">t-", 1).size).to eq(n + 1)
    create(:project, created_at: Date.yesterday - 1)
    expect(cost_query("projects", "created_at", ">t-", 1).size).to eq(n + 1)
  end

  it "does t- (n days ago)" do
    n = cost_query("projects", "created_at", "t-", 1).size
    create(:project, created_at: Date.yesterday)
    expect(cost_query("projects", "created_at", "t-", 1).size).to eq(n + 1)
    create(:project, created_at: Date.yesterday - 2)
    expect(cost_query("projects", "created_at", "t-", 1).size).to eq(n + 1)
  end

  it "does <t- (before the day which is n days ago)" do
    n = cost_query("projects", "created_at", "<t-", 1).size
    create(:project, created_at: Time.zone.today)
    expect(cost_query("projects", "created_at", "<t-", 1).size).to eq(n)
    create(:project, created_at: Date.yesterday - 1)
    expect(cost_query("projects", "created_at", "<t-", 1).size).to eq(n + 1)
  end

  # Our own operators
  describe "projects with children" do
    it "does =_child_projects" do
      expect(cost_query("projects", "id", "=_child_projects", project1.id).size).to eq(1)
      p_c1 = create_project parent: project1
      expect(cost_query("projects", "id", "=_child_projects", project1.id).size).to eq(2)
      create_project parent: p_c1
      expect(cost_query("projects", "id", "=_child_projects", project1.id).size).to eq(3)
    end

    it "does =_child_projects on multiple projects" do
      expect(cost_query("projects", "id", "=_child_projects", project1.id, project2.id).size).to eq(2)
      p1_c1 = create_project parent: project1
      p2_c1 = create_project parent: project2
      expect(cost_query("projects", "id", "=_child_projects", project1.id, project2.id).size).to eq(4)
      p1_c1_c1 = create_project parent: p1_c1
      create_project parent: p1_c1_c1
      create_project parent: p2_c1
      expect(cost_query("projects", "id", "=_child_projects", project1.id, project2.id).size).to eq(7)
    end

    it "does !_child_projects" do
      expect(cost_query("projects", "id", "!_child_projects", project1.id).size).to eq(1)
      p_c1 = create_project parent: project1
      expect(cost_query("projects", "id", "!_child_projects", project1.id).size).to eq(1)
      create_project parent: project1
      create_project parent: p_c1
      expect(cost_query("projects", "id", "!_child_projects", project1.id).size).to eq(1)
      create_project
      expect(cost_query("projects", "id", "!_child_projects", project1.id).size).to eq(2)
    end

    it "does !_child_projects on multiple projects" do
      expect(cost_query("projects", "id", "!_child_projects", project1.id, project2.id).size).to eq(0)
      p1_c1 = create_project parent: project1
      p2_c1 = create_project parent: project2
      create_project
      expect(cost_query("projects", "id", "!_child_projects", project1.id, project2.id).size).to eq(1)
      p1_c1_c1 = create_project parent: p1_c1
      create_project parent: p1_c1_c1
      create_project parent: p2_c1
      create_project
      expect(cost_query("projects", "id", "!_child_projects", project1.id, project2.id).size).to eq(2)
    end

    it "does !_child_projects on multiple projects as a string" do
      expect(cost_query("projects", "id", "!_child_projects", "#{project1.id}, #{project2.id}").size).to eq(0)
      p1_c1 = create_project parent: project1
      p2_c1 = create_project parent: project2
      create_project
      expect(cost_query("projects", "id", "!_child_projects", "#{project1.id}, #{project2.id}").size).to eq(1)
      p1_c1_c1 = create_project parent: p1_c1
      create_project parent: p1_c1_c1
      create_project parent: p2_c1
      create_project
      expect(cost_query("projects", "id", "!_child_projects", "#{project1.id}, #{project2.id}").size).to eq(2)
    end
  end

  describe "work package with descendants" do
    let!(:work_package) { create(:work_package, project: project1) }
    let!(:other_work_package) { create(:work_package, project: project2) }

    it "does =_child_work_packages" do
      expect(cost_query("work_packages", "id", "=_child_work_packages", work_package.id).size).to eq(1)
      wp1 = create(:work_package, project: work_package.project, parent: work_package)
      expect(cost_query("work_packages", "id", "=_child_work_packages", work_package.id).size).to eq(2)
      create(:work_package, project: work_package.project, parent: wp1)
      expect(cost_query("work_packages", "id", "=_child_work_packages", work_package.id).size).to eq(3)
    end

    it "does =_child_work_packages on multiple work packages" do
      expect(cost_query("work_packages", "id", "=_child_work_packages", work_package.id, other_work_package.id).size).to eq(2)
      wp1 = create(:work_package, project: work_package.project, parent: work_package)
      wp2 = create(:work_package, project: other_work_package.project, parent: other_work_package)
      expect(cost_query("work_packages", "id", "=_child_work_packages", work_package.id, other_work_package.id).size).to eq(4)

      wp3 = create(:work_package, project: work_package.project, parent: wp1)
      create(:work_package, project: work_package.project, parent: wp3)
      create(:work_package, project: other_work_package.project, parent: wp2)
      expect(cost_query("work_packages", "id", "=_child_work_packages", work_package.id, other_work_package.id).size).to eq(7)
    end

    it "does !_child_work_packages" do
      expect(cost_query("work_packages", "id", "!_child_work_packages", work_package.id).size).to eq(1)
      wp3 = create(:work_package, project: work_package.project, parent: work_package)
      expect(cost_query("work_packages", "id", "!_child_work_packages", work_package.id).size).to eq(1)
      create(:work_package, project: work_package.project, parent: wp3)
      expect(cost_query("work_packages", "id", "!_child_work_packages", work_package.id).size).to eq(1)
      create(:work_package, project: project1)
      expect(cost_query("work_packages", "id", "!_child_work_packages", work_package.id).size).to eq(2)
    end

    it "does !_child_work_packages on multiple work packages" do
      expect(cost_query("work_packages", "id", "!_child_work_packages", work_package.id, other_work_package.id).size).to eq(0)
      wp1 = create(:work_package, project: work_package.project, parent: work_package)
      wp2 = create(:work_package, project: other_work_package.project, parent: other_work_package)
      wp3 = create(:work_package, project: work_package.project)
      expect(cost_query("work_packages", "id", "!_child_work_packages", work_package.id, other_work_package.id).size).to eq(1)

      create(:work_package, project: work_package.project, parent: wp1)
      create(:work_package, project: work_package.project, parent: wp2)
      create(:work_package, project: work_package.project, parent: wp3)
      create(:work_package, project: work_package.project)
      expect(cost_query("work_packages", "id", "!_child_work_packages", work_package.id, other_work_package.id).size).to eq(3)
    end

    it "does !_child_work_packages on multiple work packages as a string" do
      expect(cost_query("work_packages", "id", "!_child_work_packages",
                        "#{work_package.id}, #{other_work_package.id}").size).to eq(0)
      wp1 = create(:work_package, project: work_package.project, parent: work_package)
      wp2 = create(:work_package, project: other_work_package.project, parent: other_work_package)
      wp3 = create(:work_package, project: work_package.project)
      expect(cost_query("work_packages", "id", "!_child_work_packages",
                        "#{work_package.id}, #{other_work_package.id}").size).to eq(1)

      create(:work_package, project: work_package.project, parent: wp1)
      create(:work_package, project: work_package.project, parent: wp2)
      create(:work_package, project: work_package.project, parent: wp3)
      create(:work_package, project: work_package.project)
      expect(cost_query("work_packages", "id", "!_child_work_packages",
                        "#{work_package.id}, #{other_work_package.id}").size).to eq(3)
    end
  end

  it "does =n" do
    rate = create(:cost_rate, rate: 13.37)
    ce1 = create(:cost_entry, units: 1, rate: rate, cost_type: rate.cost_type)
    ce2 = create(:cost_entry, units: 1, rate: rate, cost_type: rate.cost_type)
    create(:cost_entry, units: 2, rate: rate, cost_type: rate.cost_type)

    expect(query_on_entries("costs", "=n", 13.37).pluck("id")).to contain_exactly(ce1.id, ce2.id)
  end

  describe "=n value escaping" do
    let(:rate) { create(:cost_rate, rate: 10.0) }

    before do
      create(:cost_entry, units: 1, rate:, cost_type: rate.cost_type)
      create(:cost_entry, units: 1, rate:, cost_type: rate.cost_type)
    end

    it "tries to convert invalid values" do
      expect(query_on_entries("costs", "=n", "0/**/OR/**/1=1")).to be_empty
    end

    it "returns the correct rows for a legitimate numeric value" do
      expect(query_on_entries("costs", "=n", "10.0").size).to eq(2)
      expect(query_on_entries("costs", "=n", "20.0").size).to eq(0)
    end
  end

  it "does 0" do
    expect(query_on_entries("costs", "0").size).to eq(Entry.all.count { |e| e.costs == 0 })
  end

  # y/n seem are for filtering overridden costs
  it "does y" do
    expect(query_on_entries("overridden_costs", "y").size).to eq(Entry.all.count { |e| !e.overridden_costs.nil? })
  end

  it "does n" do
    expect(query_on_entries("overridden_costs", "n").size).to eq(Entry.all.count { |e| e.overridden_costs == nil })
  end

  it "does =d" do
    # assuming that there aren't more than one project created at the same time
    expect(cost_query("projects", "created_at", "=d", Project.order(Arel.sql("id ASC")).first.created_at).size).to eq(1)
  end

  it "does <d" do
    expect(cost_query("projects", "created_at", "<d", Time.zone.now).size).to eq(Project.count)
  end

  it "does <>d" do
    expect(cost_query("projects", "created_at", "<>d", Time.zone.now, 5.minutes.from_now).size).to eq(0)
  end

  it "does >d" do
    # assuming that all projects were created in the past
    expect(cost_query("projects", "created_at", ">d", Time.zone.now).size).to eq(0)
  end

  describe "arity" do
    arities = { "t" => 0, "w" => 0, "<>d" => 2, ">d" => 1 }
    arities.each do |o, a|
      it("#{o} should take #{a} values") { expect(o.to_operator.arity).to eq(a) }
    end
  end
end
