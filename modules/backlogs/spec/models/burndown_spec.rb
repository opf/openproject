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

RSpec.describe Burndown do
  def set_attribute_journalized(work_package, attribute, value, day)
    work_package.reload
    work_package.send(attribute, value)
    work_package.save!
    if work_package.journals.many?
      work_package.journals[-2].update_columns(validity_period: work_package.journals[-2].created_at...day)
    end
    work_package.journals[-1].update_columns(created_at: day, updated_at: day, validity_period: day..Float::INFINITY)
  end

  let(:project) { create(:project) }
  let(:role) { create(:project_role) }
  let(:type_feature) { create(:type_feature) }
  let(:type_task) { create(:type_task) }
  let(:issue_priority) { create(:priority, is_default: true) }

  let!(:non_working_days) do
    [
      create(:non_working_day, date: Date.new(2011, 4, 2)), # Saturday
      create(:non_working_day, date: Date.new(2011, 4, 3)), # Sunday
      create(:non_working_day, date: Date.new(2011, 4, 9)), # Saturday
      create(:non_working_day, date: Date.new(2011, 4, 10)) # Sunday
    ]
  end

  let(:issue_open) { create(:status, name: "status 1", is_default: true) }
  let(:issue_closed) { create(:status, name: "status 2", is_closed: true) }
  let(:issue_resolved) { create(:status, name: "status 3", is_closed: false) }

  current_user { create(:user, member_with_roles: { project => role }) }

  subject(:burndown) { described_class.new(sprint, project) }

  describe "for an agile sprint" do
    let(:sprint) { create(:sprint, project:) }

    describe "WITH the today date fixed to April 4th, 2011 and having a 10 (working days) sprint" do
      around do |example|
        travel_to(Time.utc(2011, "apr", 4, 20, 15, 1)) { example.run }
      end

      describe "WITH having a sprint in the future" do
        before do
          sprint.start_date = Time.zone.today + 1.day
          sprint.finish_date = Time.zone.today + 6.days
          sprint.save!
        end

        it "generates an empty burndown" do
          expect(burndown.series[:story_points]).to be_empty
        end
      end

      describe "WITH having a 10 (working days) sprint and being 5 (working) days into it" do
        before do
          sprint.start_date = Time.zone.today - 7.days
          sprint.finish_date = Time.zone.today + 6.days
          sprint.save!
        end

        describe "WITH 1 work_package assigned to the sprint" do
          let(:work_package) do
            build(:work_package,
                  subject: "WorkPackage 1",
                  project:,
                  sprint:,
                  type: type_feature,
                  status: issue_open,
                  priority: issue_priority,
                  created_at: Time.zone.today - 20.days,
                  updated_at: Time.zone.today - 20.days)
          end

          describe "WITH the work_package having story_point defined on creation" do
            before do
              work_package.story_points = 9
              work_package.save!
              work_package.last_journal.update_columns(created_at: work_package.created_at, updated_at: work_package.created_at)
            end

            describe "WITH the work_package being closed and opened again within the sprint duration" do
              before do
                set_attribute_journalized work_package, :status_id=, issue_closed.id, 6.days.ago
                set_attribute_journalized work_package, :status_id=, issue_open.id, 3.days.ago
              end

              it { expect(burndown.story_points).to eql [9.0, 0.0, 0.0, 0.0, 9.0, 9.0] }
              it { expect(burndown.story_points.unit).to be :points }

              it {
                expect(burndown.days).to eql(Day.working.from_range(from: sprint.start_date,
                                                                    to: sprint.finish_date).map(&:date))
              }

              it { expect(burndown.max[:points]).to be 9.0 }
              it { expect(burndown.story_points_ideal).to eql [9.0, 8.0, 7.0, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0, 0.0] }
            end

            describe "WITH the work_package marked as resolved and consequently 'done'" do
              before do
                set_attribute_journalized work_package, :status_id=, issue_resolved.id, 6.days.ago
                set_attribute_journalized work_package, :status_id=, issue_open.id, 3.days.ago
                project.done_statuses << issue_resolved
              end

              it { expect(burndown.story_points).to eql [9.0, 0.0, 0.0, 0.0, 9.0, 9.0] }
            end

            describe "WITH all non-closed statuses also configured as done for the project" do
              # Edge case: every status (open, resolved) is treated as done.
              # open_status_ids becomes empty, so the query should return 0
              # remaining story points rather than incorrectly
              # summing *everything*.
              before do
                work_package.story_points = 9
                work_package.save!
                work_package.last_journal.update_columns(created_at: work_package.created_at,
                                                         updated_at: work_package.created_at)
                # Configure every non-closed status as a done status for the project
                project.done_statuses << issue_open
                project.done_statuses << issue_resolved
              end

              it "shows 0.0 remaining story points for all days" do
                expect(burndown.story_points).to eql [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
              end
            end
          end
        end

        describe "WITH 10 stories assigned to the sprint" do
          let!(:stories) do
            stories = []

            10.times do |i|
              stories[i] = create(:work_package,
                                  subject: "WorkPackage #{i}",
                                  project:,
                                  sprint:,
                                  type: type_feature,
                                  status: issue_open,
                                  priority: issue_priority,
                                  created_at: Time.zone.today - (20 - i).days,
                                  updated_at: Time.zone.today - (20 - i).days)
              stories[i].last_journal.update_columns(created_at: stories[i].created_at,
                                                     updated_at: stories[i].created_at,
                                                     validity_period: stories[i].created_at..Float::INFINITY)
            end

            stories
          end

          describe "WITH each work_package having story points defined at start" do
            before do
              stories.each do |s|
                set_attribute_journalized s, :story_points=, 10, sprint.start_date - 3.days
              end
            end

            describe "WITH 5 stories having been reduced to 0 story points, one work_package per day" do
              before do
                5.times do |i|
                  set_attribute_journalized stories[i], :story_points=, nil, sprint.start_date + i.days + 1.hour
                end
              end

              describe "THEN" do
                it { expect(burndown.story_points).to eql [90.0, 80.0, 70.0, 60.0, 50.0, 50.0] }
                it { expect(burndown.story_points.unit).to be :points }

                it {
                  expect(burndown.days).to eql(Day.working.from_range(from: sprint.start_date,
                                                                      to: sprint.finish_date).map(&:date))
                }

                it { expect(burndown.max[:points]).to be 90.0 }
                it { expect(burndown.story_points_ideal).to eql [90.0, 80.0, 70.0, 60.0, 50.0, 40.0, 30.0, 20.0, 10.0, 0.0] }
              end
            end
          end
        end
      end
    end

    context "without dates on the sprint" do
      let(:sprint) { create(:sprint, project:, start_date: nil, finish_date: nil) }
      let(:work_package) do
        build(:work_package,
              :created_in_past,
              subject: "WorkPackage 1",
              project:,
              sprint:,
              type: type_feature,
              status: issue_open,
              priority: issue_priority,
              created_at: Time.zone.today - 20.days,
              updated_at: Time.zone.today - 20.days)
      end

      it "generates an empty burndown" do
        expect(burndown.series[:story_points]).to be_empty
      end
    end
  end
end
