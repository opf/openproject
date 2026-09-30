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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

# Scenario: a work package has been moved on the calendar. The moved work
# package has children, parents, followers, and/or predecessors. The
# +ScheduleDependency+ created for the moved work package will have one
# +Dependency+ instance per work package that may need to change due to the
# move. These dependencies are the subjects under test.
RSpec.describe WorkPackages::ScheduleDependency::Dependency do
  subject(:dependency) { checked_dependency_for(work_package_used_in_dependency) }

  create_shared_association_defaults_for_work_package_factory

  shared_let(:work_package, refind: true) { create(:work_package, subject: "moved") }

  let(:schedule_dependency) { WorkPackages::ScheduleDependency.new(work_package) }

  def dependency_for(work_package)
    schedule_dependency.dependencies[work_package]
  end

  def checked_dependency_for(work_package)
    dependency_for(work_package).tap do |dependency|
      if dependency.nil?
        available = schedule_dependency.dependencies.keys.map { it.subject.inspect }.to_sentence
        raise ArgumentError, "Unable to find dependency for work package #{work_package.subject.inspect}; " \
                             "ScheduleDependency instance has dependencies for work packages #{available}"
      end
    end
  end

  def create_predecessor_of(work_package, **attributes)
    work_package.update_column(:schedule_manually, false)
    create(:work_package,
           subject: "predecessor of #{work_package.subject}",
           schedule_manually: true,
           **attributes).tap do |predecessor|
      create(:follows_relation, from: work_package, to: predecessor)
    end
  end

  def create_follower_of(work_package, **attributes)
    create(:work_package,
           subject: "follower of #{work_package.subject}",
           schedule_manually: false,
           **attributes).tap do |follower|
      create(:follows_relation, from: follower, to: work_package)
    end
  end

  def create_parent_of(work_package)
    create(:work_package,
           subject: "parent of #{work_package.subject}",
           schedule_manually: false).tap do |parent|
      work_package.update(parent:)
    end
  end

  def create_child_of(work_package, **attributes)
    work_package.update_column(:schedule_manually, false)
    child_attributes = attributes.reverse_merge(
      subject: "child of #{work_package.subject}",
      parent: work_package,
      schedule_manually: true
    )
    create(:work_package, **child_attributes)
  end

  describe "#dependent_ids" do
    context "when the work_package has a follower" do
      shared_let(:follower) { create_follower_of(work_package) }

      context "for dependency of the follower" do
        let(:work_package_used_in_dependency) { follower }

        it "returns an array with the work package id" do
          expect(subject.dependent_ids).to eq([work_package.id])
        end

        context "when the work package is deleted" do
          before do
            work_package.destroy
          end

          it "returns an empty array" do
            expect(dependency_for(follower)).to be_nil
          end
        end
      end
    end

    context "when the work_package has a parent" do
      shared_let(:parent) { create_parent_of(work_package) }

      context "for dependency of the parent" do
        let(:work_package_used_in_dependency) { parent }

        it "returns an array with the work package id" do
          expect(subject.dependent_ids).to eq([work_package.id])
        end

        context "when the work package is deleted" do
          before do
            work_package.destroy
          end

          it "returns an empty array" do
            expect(dependency_for(parent)).to be_nil
          end
        end
      end
    end

    context "when the work_package has a follower which has a child automatically scheduled" do
      let!(:follower) { create_follower_of(work_package) }
      let!(:follower_child) { create_child_of(follower, schedule_manually: false) }

      context "for dependency of the child" do
        let(:work_package_used_in_dependency) { follower_child }

        it "returns an array with the work_package id" do
          expect(subject.dependent_ids).to eq([work_package.id])
        end
      end

      context "for dependency of the follower" do
        let(:work_package_used_in_dependency) { follower }

        it "returns an array with the work_package id and the follower child id" do
          expect(subject.dependent_ids).to contain_exactly(work_package.id, follower_child.id)
        end
      end
    end

    context "when the work_package has a follower which has a child manually scheduled" do
      let!(:follower) { create_follower_of(work_package) }
      let!(:follower_child) { create_child_of(follower, schedule_manually: true) }

      context "for dependency of the child" do
        it "has no dependency as its date do not depend on any other work package" do
          expect(dependency_for(follower_child)).to be_nil
        end
      end

      context "for dependency of the follower" do
        let(:work_package_used_in_dependency) { follower }

        it "has its dates do not depend on the moved work package but on the follower child" do
          expect(dependency_for(follower)).to be_nil
        end
      end
    end

    context "when the work_package has multiple parents and followers" do
      let!(:first_follower) { create_follower_of(work_package) }
      let!(:second_follower) { create_follower_of(work_package) }
      let!(:first_follower_parent) { create_parent_of(first_follower) }
      let!(:first_follower_grandparent) { create_parent_of(first_follower_parent) }

      context "for dependency of the first follower parent" do
        let(:work_package_used_in_dependency) { first_follower_parent }

        it "returns an array with the first follower id" do
          expect(subject.dependent_ids).to contain_exactly(first_follower.id)
        end
      end

      context "for dependency of the first follower grandparent" do
        let(:work_package_used_in_dependency) { first_follower_grandparent }

        it "returns an array with the first follower and the first follower parent ids" do
          expect(subject.dependent_ids).to contain_exactly(first_follower.id, first_follower_parent.id)
        end
      end

      context "for dependency of the second follower" do
        let(:work_package_used_in_dependency) { second_follower }

        it "returns an array with the work_package id" do
          expect(subject.dependent_ids).to contain_exactly(work_package.id)
        end
      end
    end

    context "with more complex relations" do
      context "when has two consecutive followers" do
        shared_let(:follower) { create_follower_of(work_package) }
        shared_let(:follower_follower) { create_follower_of(follower) }

        context "for dependency of the first follower" do
          let(:work_package_used_in_dependency) { follower }

          it "returns an array with the work_package id" do
            expect(subject.dependent_ids).to contain_exactly(work_package.id)
          end
        end

        context "for dependency of the second follower" do
          let(:work_package_used_in_dependency) { follower_follower }

          it "returns an array with only the first follower id" do
            expect(subject.dependent_ids).to contain_exactly(follower.id)
          end

          context "when the first follower is deleted" do
            before do
              follower.destroy
            end

            it "returns an empty array" do
              expect(dependency_for(follower_follower)).to be_nil
            end
          end
        end
      end

      context "when has a follower which has a predecessor" do
        let!(:follower) { create_follower_of(work_package) }
        let!(:follower_predecessor) { create_predecessor_of(follower) }

        context "for dependency of the follower" do
          let(:work_package_used_in_dependency) { follower }

          it "returns an array with the work_package id" do
            expect(subject.dependent_ids).to contain_exactly(work_package.id)
          end
        end
      end

      context "when has a follower which has a parent and a child automatically scheduled" do
        let!(:follower) { create_follower_of(work_package) }
        let!(:follower_parent) { create_parent_of(follower) }
        let!(:follower_child) { create_child_of(follower, schedule_manually: false) }

        context "for dependency of the follower child" do
          let(:work_package_used_in_dependency) { follower_child }

          it "returns an array with the work_package id" do
            expect(subject.dependent_ids).to contain_exactly(work_package.id)
          end
        end

        context "for dependency of the follower parent" do
          let(:work_package_used_in_dependency) { follower_parent }

          it "returns an array with the follower and the follower child ids" do
            expect(subject.dependent_ids).to contain_exactly(follower.id, follower_child.id)
          end
        end
      end

      context "when has a follower which has a parent and a child manually scheduled" do
        let!(:follower) { create_follower_of(work_package) }
        let!(:follower_parent) { create_parent_of(follower) }
        let!(:follower_child) { create_child_of(follower, schedule_manually: true) }

        context "for dependency of the follower child" do
          let(:work_package_used_in_dependency) { follower_child }

          it "has no dependency as its dates do not depend on any other work package (it's manually scheduled)" do
            expect(dependency_for(follower_child)).to be_nil
          end
        end

        context "for dependency of the follower parent" do
          let(:work_package_used_in_dependency) { follower_parent }

          it "has no dependency as its dates depend on the follower child, and this one is manually scheduled" do
            expect(dependency_for(follower_parent)).to be_nil
          end
        end
      end
    end
  end

  describe "#soonest_start_date" do
    let(:work_package_used_in_dependency) { work_package }

    before do
      work_package.update(due_date: Date.current)
    end

    context "with a moved predecessor" do
      it "returns the soonest start date from the predecessors" do
        follower = create_follower_of(work_package)
        expect(dependency_for(follower).soonest_start_date).to eq(work_package.due_date + 1.day)
      end
    end

    context "with an unmoved predecessor" do
      it "returns the soonest start date from the predecessors" do
        follower = create_follower_of(work_package)
        unmoved_follower_predecessor = create_predecessor_of(follower, due_date: Date.current + 4.days)
        expect(dependency_for(follower).soonest_start_date).to eq(unmoved_follower_predecessor.due_date + 1.day)
      end
    end

    context "with non working days" do
      let!(:tomorrow_we_do_not_work!) { create(:non_working_day, date: Date.tomorrow) }

      it "returns the soonest start date being a working day" do
        follower = create_follower_of(work_package)
        expect(dependency_for(follower).soonest_start_date).to eq(work_package.due_date + 2.days)
      end
    end
  end
end
