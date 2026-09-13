# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require 'rails_helper'

RSpec.describe Bim::ElementProgress, type: :model do
  subject(:element_progress) { build(:element_progress) }

  describe 'associations' do
    it { is_expected.to belong_to(:ifc_model).class_name('Bim::IfcModels::IfcModel') }
    it { is_expected.to belong_to(:baseline).class_name('Bim::ProgressBaseline').optional }
    it { is_expected.to belong_to(:work_package).class_name('WorkPackage').optional }
    it { is_expected.to belong_to(:updated_by).class_name('User').optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:element_id) }
    it { is_expected.to validate_presence_of(:ifc_model_id) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:percent_complete) }

    it {
      is_expected.to validate_numericality_of(:percent_complete)
        .is_greater_than_or_equal_to(0)
        .is_less_than_or_equal_to(100)
    }

    describe 'actual_dates_after_planned' do
      it 'is invalid when actual_start < planned_start' do
        element_progress.planned_start = Date.current
        element_progress.actual_start = 1.day.ago

        expect(element_progress).not_to be_valid
        expect(element_progress.errors[:actual_start]).to include('cannot be before planned start')
      end

      it 'is invalid when actual_finish < actual_start' do
        element_progress.actual_start = Date.current
        element_progress.actual_finish = 1.day.ago

        expect(element_progress).not_to be_valid
        expect(element_progress.errors[:actual_finish]).to include('cannot be before actual start')
      end
    end

    describe 'percent_complete_matches_status' do
      it 'is invalid when completed but percent_complete != 100' do
        element_progress.status = :completed
        element_progress.percent_complete = 90

        expect(element_progress).not_to be_valid
        expect(element_progress.errors[:percent_complete]).to include('must be 100 when status is completed')
      end

      it 'is invalid when planned but percent_complete > 0' do
        element_progress.status = :planned
        element_progress.percent_complete = 10

        expect(element_progress).not_to be_valid
        expect(element_progress.errors[:percent_complete]).to include('must be 0 when status is planned')
      end
    end
  end

  describe 'scopes' do
    let(:model) { create(:ifc_model) }
    let!(:elem1) { create(:element_progress, ifc_model: model) }
    let!(:elem2) { create(:element_progress, ifc_model: model) }
    let!(:other_elem) { create(:element_progress) }

    describe '.for_model' do
      it 'returns elements for specified model' do
        expect(described_class.for_model(model)).to contain_exactly(elem1, elem2)
      end
    end

    describe '.current' do
      let!(:baseline_elem) { create(:element_progress, :with_baseline, ifc_model: model) }

      it 'returns only current progress (no baseline)' do
        expect(described_class.current).to contain_exactly(elem1, elem2, other_elem)
      end
    end

    describe '.for_baseline' do
      let(:baseline) { create(:progress_baseline) }
      let!(:baseline_elem) { create(:element_progress, baseline: baseline) }

      it 'returns elements for specified baseline' do
        expect(described_class.for_baseline(baseline)).to contain_exactly(baseline_elem)
      end
    end

    describe '.by_type' do
      let!(:wall) { create(:element_progress, :wall, ifc_model: model) }
      let!(:door) { create(:element_progress, :door, ifc_model: model) }

      it 'filters by element type' do
        expect(described_class.by_type('IfcWall')).to include(wall)
        expect(described_class.by_type('IfcWall')).not_to include(door)
      end
    end

    describe '.delayed' do
      let!(:delayed) { create(:element_progress, :delayed, ifc_model: model) }
      let!(:on_time) { create(:element_progress, :on_schedule, ifc_model: model) }

      it 'returns delayed elements' do
        expect(described_class.delayed).to include(delayed)
        expect(described_class.delayed).not_to include(on_time)
      end
    end

    describe '.ahead_of_schedule' do
      let!(:ahead) { create(:element_progress, :ahead_of_schedule, ifc_model: model) }
      let!(:on_time) { create(:element_progress, :on_schedule, ifc_model: model) }

      it 'returns ahead-of-schedule elements' do
        expect(described_class.ahead_of_schedule).to include(ahead)
        expect(described_class.ahead_of_schedule).not_to include(on_time)
      end
    end
  end

  describe '#start!' do
    let(:user) { create(:user) }
    let(:element_progress) { create(:element_progress, :planned) }

    it 'changes status to in_progress' do
      element_progress.start!(user: user)
      expect(element_progress.status).to eq('in_progress')
    end

    it 'sets actual_start to current date' do
      element_progress.start!(user: user)
      expect(element_progress.actual_start).to eq(Date.current)
    end

    it 'sets percent_complete to at least 1' do
      element_progress.start!(user: user)
      expect(element_progress.percent_complete).to be >= 1
    end

    it 'records the user' do
      element_progress.start!(user: user)
      expect(element_progress.updated_by).to eq(user)
    end
  end

  describe '#complete!' do
    let(:user) { create(:user) }
    let(:element_progress) { create(:element_progress, :in_progress) }

    it 'changes status to completed' do
      element_progress.complete!(user: user)
      expect(element_progress.status).to eq('completed')
    end

    it 'sets percent_complete to 100' do
      element_progress.complete!(user: user)
      expect(element_progress.percent_complete).to eq(100)
    end

    it 'sets actual_finish to current date' do
      element_progress.complete!(user: user)
      expect(element_progress.actual_finish).to eq(Date.current)
    end

    it 'records the user' do
      element_progress.complete!(user: user)
      expect(element_progress.updated_by).to eq(user)
    end
  end

  describe '#hold!' do
    let(:user) { create(:user) }
    let(:element_progress) { create(:element_progress, :in_progress) }

    it 'changes status to on_hold' do
      element_progress.hold!(user: user)
      expect(element_progress.status).to eq('on_hold')
    end

    it 'preserves percent_complete' do
      original_percent = element_progress.percent_complete
      element_progress.hold!(user: user)
      expect(element_progress.percent_complete).to eq(original_percent)
    end

    it 'records the user' do
      element_progress.hold!(user: user)
      expect(element_progress.updated_by).to eq(user)
    end
  end

  describe '#resume!' do
    let(:user) { create(:user) }
    let(:element_progress) { create(:element_progress, :on_hold) }

    it 'changes status to in_progress' do
      element_progress.resume!(user: user)
      expect(element_progress.status).to eq('in_progress')
    end

    it 'records the user' do
      element_progress.resume!(user: user)
      expect(element_progress.updated_by).to eq(user)
    end
  end

  describe '#update_progress!' do
    let(:user) { create(:user) }
    let(:element_progress) { create(:element_progress, :planned) }

    context 'when progress is 0' do
      it 'sets status to planned' do
        element_progress.update_progress!(0, user: user)
        expect(element_progress.status).to eq('planned')
      end
    end

    context 'when progress is 100' do
      it 'sets status to completed' do
        element_progress.update_progress!(100, user: user)
        expect(element_progress.status).to eq('completed')
      end

      it 'sets actual_finish' do
        element_progress.update_progress!(100, user: user)
        expect(element_progress.actual_finish).to eq(Date.current)
      end
    end

    context 'when progress is between 0 and 100' do
      it 'sets status to in_progress for planned element' do
        element_progress.update_progress!(50, user: user)
        expect(element_progress.status).to eq('in_progress')
      end

      it 'sets actual_start if not set' do
        element_progress.update_progress!(50, user: user)
        expect(element_progress.actual_start).to eq(Date.current)
      end

      it 'preserves status for on_hold element' do
        element_progress.status = :on_hold
        element_progress.save!
        element_progress.update_progress!(50, user: user)
        expect(element_progress.status).to eq('on_hold')
      end
    end
  end

  describe '#schedule_variance_days' do
    it 'returns nil when planned_finish is nil' do
      element_progress.planned_finish = nil
      expect(element_progress.schedule_variance_days).to be_nil
    end

    it 'returns nil when actual_finish is nil' do
      element_progress.actual_finish = nil
      expect(element_progress.schedule_variance_days).to be_nil
    end

    it 'returns positive days when delayed' do
      element_progress.planned_finish = 5.days.ago
      element_progress.actual_finish = Date.current
      expect(element_progress.schedule_variance_days).to eq(5)
    end

    it 'returns negative days when ahead' do
      element_progress.planned_finish = Date.current
      element_progress.actual_finish = 5.days.ago
      expect(element_progress.schedule_variance_days).to eq(-5)
    end
  end

  describe '#delayed?' do
    it 'returns true when schedule_variance_days > 0' do
      element_progress = create(:element_progress, :delayed)
      expect(element_progress.delayed?).to be true
    end

    it 'returns false when schedule_variance_days <= 0' do
      element_progress = create(:element_progress, :on_schedule)
      expect(element_progress.delayed?).to be false
    end

    it 'returns false when schedule_variance_days is nil' do
      element_progress.planned_finish = nil
      expect(element_progress.delayed?).to be false
    end
  end

  describe '#ahead_of_schedule?' do
    it 'returns true when schedule_variance_days < 0' do
      element_progress = create(:element_progress, :ahead_of_schedule)
      expect(element_progress.ahead_of_schedule?).to be true
    end

    it 'returns false when schedule_variance_days >= 0' do
      element_progress = create(:element_progress, :on_schedule)
      expect(element_progress.ahead_of_schedule?).to be false
    end
  end

  describe '#planned_duration_days' do
    it 'calculates duration from planned dates' do
      element_progress.planned_start = 10.days.ago
      element_progress.planned_finish = Date.current
      expect(element_progress.planned_duration_days).to eq(10)
    end

    it 'returns nil when dates are missing' do
      element_progress.planned_start = nil
      expect(element_progress.planned_duration_days).to be_nil
    end
  end

  describe '#actual_duration_days' do
    it 'calculates duration from actual dates' do
      element_progress.actual_start = 10.days.ago
      element_progress.actual_finish = Date.current
      expect(element_progress.actual_duration_days).to eq(10)
    end

    it 'returns nil when dates are missing' do
      element_progress.actual_start = nil
      expect(element_progress.actual_duration_days).to be_nil
    end
  end

  describe '#display_name' do
    it 'returns element_name if present' do
      element_progress.element_name = 'Main Wall'
      expect(element_progress.display_name).to eq('Main Wall')
    end

    it 'returns element_id as fallback' do
      element_progress.element_name = nil
      element_progress.element_id = 'wall-123'
      expect(element_progress.display_name).to eq('wall-123')
    end
  end

  describe '#complete?' do
    it 'returns true when status is completed and percent is 100' do
      element_progress = create(:element_progress, :completed)
      expect(element_progress.complete?).to be true
    end

    it 'returns false otherwise' do
      element_progress = create(:element_progress, :in_progress)
      expect(element_progress.complete?).to be false
    end
  end

  describe '#in_progress?' do
    it 'returns true when status is in_progress' do
      element_progress = create(:element_progress, :in_progress)
      expect(element_progress.in_progress?).to be true
    end

    it 'returns false otherwise' do
      element_progress = create(:element_progress, :planned)
      expect(element_progress.in_progress?).to be false
    end
  end

  describe '#started?' do
    it 'returns true when actual_start is present' do
      element_progress.actual_start = Date.current
      expect(element_progress.started?).to be true
    end

    it 'returns true when percent_complete > 0' do
      element_progress.actual_start = nil
      element_progress.percent_complete = 10
      expect(element_progress.started?).to be true
    end

    it 'returns false otherwise' do
      element_progress.actual_start = nil
      element_progress.percent_complete = 0
      expect(element_progress.started?).to be false
    end
  end

  describe '#progress_color' do
    it 'returns green for completed' do
      element_progress = build(:element_progress, :completed)
      expect(element_progress.progress_color).to eq('#4caf50')
    end

    it 'returns red for delayed in_progress' do
      element_progress = create(:element_progress, :delayed)
      expect(element_progress.progress_color).to eq('#f44336')
    end

    it 'returns blue for ahead in_progress' do
      element_progress = create(:element_progress, :ahead_of_schedule)
      element_progress.status = :in_progress
      element_progress.percent_complete = 50
      element_progress.save!
      expect(element_progress.progress_color).to eq('#2196f3')
    end

    it 'returns orange for on-track in_progress' do
      element_progress = build(:element_progress, :in_progress)
      expect(element_progress.progress_color).to eq('#ff9800')
    end

    it 'returns gray for on_hold' do
      element_progress = build(:element_progress, :on_hold)
      expect(element_progress.progress_color).to eq('#9e9e9e')
    end

    it 'returns light gray for planned' do
      element_progress = build(:element_progress, :planned)
      expect(element_progress.progress_color).to eq('#e0e0e0')
    end
  end

  describe '#progress_variance_against' do
    let(:baseline) { create(:progress_baseline) }
    let(:element_progress) { create(:element_progress, element_id: 'wall-1', percent_complete: 75) }

    before do
      create(:element_progress,
             ifc_model: element_progress.ifc_model,
             element_id: 'wall-1',
             baseline: baseline,
             percent_complete: 50)
    end

    it 'calculates variance against baseline' do
      variance = element_progress.progress_variance_against(baseline)
      expect(variance).to eq(25)
    end

    it 'returns nil when baseline has no matching element' do
      other_elem = create(:element_progress, element_id: 'wall-999')
      variance = other_elem.progress_variance_against(baseline)
      expect(variance).to be_nil
    end
  end
end
