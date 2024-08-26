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

require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

RSpec.describe CostQuery, :reporting_query_helper do
  minimal_query

  let!(:project1) { create(:project, name: "project1", created_at: 5.minutes.ago) }
  let!(:project2) { create(:project, name: "project2", created_at: 6.minutes.ago) }

  describe CostQuery::Operator do
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
      create(:project, created_at: Date.today)
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
      create(:project, created_at: Date.today)
      expect(cost_query("projects", "created_at", "<t-", 1).size).to eq(n)
      create(:project, created_at: Date.yesterday - 1)
      expect(cost_query("projects", "created_at", "<t-", 1).size).to eq(n + 1)
    end

    # Our own operators
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

    it "does =n" do
      # we have a time_entry with costs==4.2 and a cost_entry with costs==2.3 in our fixtures
      expect(query_on_entries("costs", "=n", 4.2).size).to eq(Entry.all.count { |e| e.costs == 4.2 })
      expect(query_on_entries("costs", "=n", 2.3).size).to eq(Entry.all.count { |e| e.costs == 2.3 })
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
end
