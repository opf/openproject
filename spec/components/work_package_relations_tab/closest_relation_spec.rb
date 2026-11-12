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

RSpec.describe WorkPackageRelationsTab::ClosestRelation do
  let(:work_package) { build_stubbed(:work_package) }
  let(:today) { Time.zone.today }

  def follows_relation(lag: 0, **wp_attributes)
    predecessor = build_stubbed(:work_package, **wp_attributes)
    build_stubbed(:follows_relation, from: work_package, to: predecessor, lag:)
  end

  def precedes_relation(lag: 0, **wp_attributes)
    successor = build_stubbed(:work_package, **wp_attributes)
    build_stubbed(:precedes_relation, from: work_package, to: successor, lag:)
  end

  def relates_relation(**wp_attributes)
    related = build_stubbed(:work_package, **wp_attributes)
    build_stubbed(:relates_relation, from: work_package, to: related)
  end

  def closest_relation(lag: 0, **wp_attributes)
    relation = follows_relation(lag:, **wp_attributes)
    described_class.new(relation)
  end

  describe ".of" do
    it "returns the closest relation of a list of follows relations" do
      relations = [
        follows_relation(due_date: 4.days.ago),
        follows_relation(due_date: 4.days.ago, lag: 2)
      ]
      expect(described_class.of(work_package, relations)).to eq(relations.last)
    end

    it "is correct even when there is negative lag" do
      relations = [
        follows_relation(due_date: 4.days.ago),
        follows_relation(due_date: 3.days.ago, lag: -2) # 3.days.ago - 2.days = 5.days.ago
      ]
      expect(described_class.of(work_package, relations)).to eq(relations.first)

      relations = [
        follows_relation(due_date: 3.days.ago, lag: -3),
        follows_relation(due_date: 3.days.ago, lag: -1)
      ]
      expect(described_class.of(work_package, relations)).to eq(relations.second)
    end

    it "ignores relations not being 'follows' relations" do
      relations = [
        follows_relation(due_date: 4.days.ago),
        follows_relation(due_date: 4.days.ago, lag: 2),
        relates_relation(due_date: today)
      ]
      expect(described_class.of(work_package, relations)).to eq(relations.second)
    end

    it "ignores 'follows' relations not having any dates" do
      relations = [
        follows_relation(start_date: nil, due_date: nil)
      ]
      expect(described_class.of(work_package, relations)).to be_nil
    end

    it "ignores child relations" do
      child_relation = build_stubbed(:work_package, parent: work_package)
      relations = [
        child_relation
      ]
      expect(described_class.of(work_package, relations)).to be_nil
    end

    it "distinguishes between 'follows' and 'precedes' relations" do
      relations = [
        follows_relation(due_date: 4.days.ago),
        follows_relation(due_date: 4.days.ago, lag: 2),
        precedes_relation(due_date: today)
      ]
      expect(described_class.of(work_package, relations)).to eq(relations.second)
    end

    it "returns nil when there no 'follows' relations are given" do
      relations = [
        relates_relation(due_date: today),
        precedes_relation(due_date: today)
      ]
      expect(described_class.of(work_package, relations)).to be_nil
      expect(described_class.of(work_package, [])).to be_nil
    end
  end

  describe "#<=>" do
    context "without a lag" do
      context "when comparing two instances with different due dates" do
        it "compares with the respective due dates" do
          expect(closest_relation(due_date: 1.day.from_now)).to be < closest_relation(due_date: 2.days.from_now)
          expect(closest_relation(due_date: today)).to be > closest_relation(due_date: 2.days.ago)
          expect(closest_relation(due_date: today)).to be > closest_relation(due_date: nil)
          expect(closest_relation(due_date: nil)).to be < closest_relation(due_date: 1.day.ago)
        end
      end

      context "when comparing two instances with different start dates" do
        it "compares with the respective start dates" do
          expect(closest_relation(start_date: 1.day.from_now)).to be < closest_relation(start_date: 2.days.from_now)
          expect(closest_relation(start_date: today)).to be > closest_relation(start_date: 2.days.ago)
          expect(closest_relation(start_date: today)).to be > closest_relation(start_date: nil)
          expect(closest_relation(start_date: nil)).to be < closest_relation(start_date: 1.day.ago)
        end
      end

      context "when comparing two instances with same due dates" do
        it "compares with the respective created at dates, oldest > newest" do
          expect(closest_relation(due_date: 1.day.from_now)).to be > closest_relation(due_date: 1.day.from_now)
          expect(closest_relation(due_date: 2.days.ago)).to be > closest_relation(due_date: 2.days.ago)
          expect(closest_relation(due_date: nil)).to be > closest_relation(due_date: nil)
        end
      end

      context "when comparing two instances with same start dates" do
        it "compares with the respective created at dates, oldest > newest" do
          expect(closest_relation(start_date: 1.day.from_now)).to be > closest_relation(start_date: 1.day.from_now)
          expect(closest_relation(start_date: 2.days.ago)).to be > closest_relation(start_date: 2.days.ago)
          expect(closest_relation(start_date: nil)).to be > closest_relation(start_date: nil)
        end
      end

      context "when comparing two instances with both due and start dates set" do
        it "compares with the respective due dates, ignoring start dates" do
          expect(closest_relation(due_date: 10.days.from_now, start_date: today))
            .to be < closest_relation(due_date: 12.days.from_now, start_date: 2.days.ago)
          expect(closest_relation(due_date: 14.days.from_now, start_date: today))
            .to be > closest_relation(due_date: 12.days.from_now, start_date: 2.days.ago)
        end
      end
    end

    context "with a lag" do
      context "when comparing two instances with same soonest starts (due date and lag)" do
        it "compares with the respective created at dates, oldest > newest" do
          expect(closest_relation(lag: 3, due_date: 3.days.from_now))
            .to be > closest_relation(lag: 4, due_date: 2.days.from_now)
          expect(closest_relation(lag: 2, due_date: 3.days.ago))
            .to be > closest_relation(lag: 1, due_date: 4.days.ago)
          expect(closest_relation(lag: 2, due_date: nil))
            .to be > closest_relation(lag: 2, due_date: nil)
        end
      end

      context "when comparing two instances with same soonest starts (start date and lag)" do
        it "compares with the respective created at dates, oldest > newest" do
          expect(closest_relation(lag: 3, start_date: 3.days.from_now))
            .to be > closest_relation(lag: 4, start_date: 2.days.from_now)
          expect(closest_relation(lag: 2, start_date: 3.days.ago))
            .to be > closest_relation(lag: 1, start_date: 4.days.ago)
          expect(closest_relation(lag: 2, start_date: nil))
            .to be > closest_relation(lag: 2, start_date: nil)
        end
      end

      context "when comparing two instances with different soonest starts (due date and lag)" do
        it "compares with the combined due dates and lag" do
          expect(closest_relation(lag: 4, due_date: 3.days.from_now))
            .to be > closest_relation(lag: 4, due_date: 2.days.from_now)
          expect(closest_relation(lag: 1, due_date: 3.days.ago))
            .to be < closest_relation(lag: 4, due_date: 3.days.ago)
          expect(closest_relation(lag: 4, due_date: nil))
            .to be < closest_relation(lag: 4, due_date: 2.days.from_now)
          expect(closest_relation(lag: 1, due_date: 3.days.ago))
            .to be > closest_relation(lag: 4, due_date: nil)
        end
      end

      context "when comparing two instances with different soonest starts (start date and lag)" do
        it "compares with the combined start dates and lag" do
          expect(closest_relation(lag: 4, start_date: 3.days.from_now))
            .to be > closest_relation(lag: 4, start_date: 2.days.from_now)
          expect(closest_relation(lag: 1, start_date: 3.days.ago))
            .to be < closest_relation(lag: 4, start_date: 3.days.ago)
          expect(closest_relation(lag: 4, start_date: nil))
            .to be < closest_relation(lag: 4, start_date: 2.days.from_now)
          expect(closest_relation(lag: 1, start_date: 3.days.ago))
            .to be > closest_relation(lag: 4, start_date: nil)
        end
      end
    end
  end

  describe "#soonest_start" do
    context "with a nil due and start date" do
      it "returns nil" do
        expect(closest_relation(due_date: nil, start_date: nil).soonest_start).to be_nil
        expect(closest_relation(lag: 1, due_date: nil, start_date: nil).soonest_start).to be_nil
      end
    end

    context "with a due date set" do
      let(:due_date) { Date.new(2020, 7, 14) }

      context "without a lag" do
        it "returns the day after the due date" do
          expect(closest_relation(due_date:).soonest_start).to eq(Date.new(2020, 7, 15))
        end
      end

      context "with a positive lag" do
        it "returns the day after the due date plus the lag" do
          expect(closest_relation(lag: 3, due_date:).soonest_start).to eq(Date.new(2020, 7, 18))
        end
      end

      context "with a negative lag" do
        it "returns the combined due date and lag" do
          expect(closest_relation(lag: -2, due_date:).soonest_start).to eq(Date.new(2020, 7, 13))
        end
      end
    end

    context "with a start date set" do
      let(:start_date) { Date.new(2020, 7, 14) }

      context "with a zero lag" do
        it "returns the day after the start date" do
          expect(closest_relation(start_date:).soonest_start).to eq(Date.new(2020, 7, 15))
        end
      end

      context "with a positive lag" do
        it "returns the day after the start date plus the lag" do
          expect(closest_relation(lag: 3, start_date:).soonest_start).to eq(Date.new(2020, 7, 18))
        end
      end

      context "with a negative lag" do
        it "returns the combined start date and lag" do
          expect(closest_relation(lag: -2, start_date:).soonest_start).to eq(Date.new(2020, 7, 13))
        end
      end
    end
  end

  describe "#inspect" do
    subject { closest_relation(lag: 3, due_date: Date.new(2022, 7, 4)) }

    it "outputs object for debugging" do
      expect(subject.inspect)
        .to start_with("#<WorkPackageRelationsTab::ClosestRelation soonest_start: 2022-07-08")
        .and include(subject.relation.inspect)
    end
  end
end
