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

RSpec.describe Bim::ProgressBaseline, type: :model do
  subject(:baseline) { build(:progress_baseline) }

  describe 'associations' do
    it { is_expected.to belong_to(:ifc_model).class_name('Bim::IfcModels::IfcModel') }
    it { is_expected.to belong_to(:created_by).class_name('User') }
    it { is_expected.to have_many(:element_progresses).class_name('Bim::ElementProgress') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:snapshot_date) }
    it { is_expected.to validate_presence_of(:ifc_model_id) }

    it { is_expected.to validate_numericality_of(:total_elements).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:completed_elements).is_greater_than_or_equal_to(0) }
    it {
      is_expected.to validate_numericality_of(:overall_progress)
        .is_greater_than_or_equal_to(0)
        .is_less_than_or_equal_to(100)
    }

    describe 'completed_elements_within_total' do
      it 'is invalid when completed > total' do
        baseline.total_elements = 100
        baseline.completed_elements = 150

        expect(baseline).not_to be_valid
        expect(baseline.errors[:completed_elements]).to include('cannot exceed total elements')
      end

      it 'is valid when completed <= total' do
        baseline.total_elements = 100
        baseline.completed_elements = 100

        expect(baseline).to be_valid
      end
    end

    describe 'only_one_current_per_model' do
      let(:model) { create(:ifc_model) }
      let!(:current_baseline) { create(:progress_baseline, :current, ifc_model: model) }

      it 'prevents creating another current baseline for same model' do
        new_baseline = build(:progress_baseline, :current, ifc_model: model)

        expect(new_baseline).not_to be_valid
        expect(new_baseline.errors[:is_current]).to include('Only one current baseline allowed per model')
      end

      it 'allows current baseline for different model' do
        other_model = create(:ifc_model)
        new_baseline = build(:progress_baseline, :current, ifc_model: other_model)

        expect(new_baseline).to be_valid
      end

      it 'allows non-current baseline for same model' do
        new_baseline = build(:progress_baseline, is_current: false, ifc_model: model)

        expect(new_baseline).to be_valid
      end
    end
  end

  describe 'scopes' do
    let(:model) { create(:ifc_model) }
    let!(:baseline1) { create(:progress_baseline, ifc_model: model) }
    let!(:baseline2) { create(:progress_baseline, ifc_model: model) }
    let!(:other_baseline) { create(:progress_baseline) }

    describe '.for_model' do
      it 'returns baselines for specified model' do
        expect(described_class.for_model(model)).to contain_exactly(baseline1, baseline2)
      end
    end

    describe '.current_baseline' do
      let!(:current) { create(:progress_baseline, :current, ifc_model: model) }

      it 'returns only current baselines' do
        expect(described_class.current_baseline).to contain_exactly(current)
      end
    end

    describe '.recent' do
      let!(:old) { create(:progress_baseline, snapshot_date: 1.year.ago, ifc_model: model) }
      let!(:recent) { create(:progress_baseline, snapshot_date: Date.current, ifc_model: model) }

      it 'returns baselines ordered by snapshot_date desc' do
        expect(described_class.recent.first).to eq(recent)
      end
    end
  end

  describe '#completion_percentage' do
    it 'returns 0 when no elements' do
      baseline.total_elements = 0
      expect(baseline.completion_percentage).to eq(0.0)
    end

    it 'calculates percentage correctly' do
      baseline.total_elements = 100
      baseline.completed_elements = 25
      expect(baseline.completion_percentage).to eq(25.0)
    end

    it 'rounds to 2 decimal places' do
      baseline.total_elements = 3
      baseline.completed_elements = 1
      expect(baseline.completion_percentage).to eq(33.33)
    end
  end

  describe '#create_snapshot!' do
    let(:model) { create(:ifc_model) }
    let(:user) { create(:user) }
    let(:baseline) { create(:progress_baseline, ifc_model: model, created_by: user) }

    before do
      # Create current progress for the model
      create(:element_progress, :completed, ifc_model: model)
      create(:element_progress, :in_progress, ifc_model: model, percent_complete: 50)
      create(:element_progress, :planned, ifc_model: model)
    end

    it 'creates snapshot of current progress' do
      expect { baseline.create_snapshot! }.to change { Bim::ElementProgress.for_baseline(baseline).count }.from(0).to(3)
    end

    it 'copies element progress records' do
      baseline.create_snapshot!

      snapshot_progresses = Bim::ElementProgress.for_baseline(baseline)
      expect(snapshot_progresses.map(&:status)).to contain_exactly('completed', 'in_progress', 'planned')
    end

    it 'updates baseline statistics' do
      baseline.create_snapshot!

      baseline.reload
      expect(baseline.total_elements).to eq(3)
      expect(baseline.completed_elements).to eq(1)
      expect(baseline.overall_progress).to eq(33.33)
    end
  end

  describe '#set_as_current!' do
    let(:model) { create(:ifc_model) }
    let!(:old_current) { create(:progress_baseline, :current, ifc_model: model) }
    let(:baseline) { create(:progress_baseline, ifc_model: model, is_current: false) }

    it 'sets this baseline as current' do
      baseline.set_as_current!
      expect(baseline.reload.is_current).to be true
    end

    it 'unsets previous current baseline' do
      baseline.set_as_current!
      expect(old_current.reload.is_current).to be false
    end
  end

  describe '#compare_to_current' do
    let(:model) { create(:ifc_model) }
    let(:baseline) { create(:progress_baseline, ifc_model: model, overall_progress: 25.0) }

    before do
      # Create baseline snapshot
      create(:element_progress, :completed, ifc_model: model, element_id: 'elem-1', baseline: baseline, percent_complete: 100)
      create(:element_progress, :planned, ifc_model: model, element_id: 'elem-2', baseline: baseline, percent_complete: 0)

      # Create current progress (advanced from baseline)
      create(:element_progress, :completed, ifc_model: model, element_id: 'elem-1', percent_complete: 100)
      create(:element_progress, :in_progress, ifc_model: model, element_id: 'elem-2', percent_complete: 50)
    end

    it 'returns variance calculation' do
      result = baseline.compare_to_current

      expect(result).to be_a(Hash)
      expect(result[:baseline_progress]).to eq(25.0)
      expect(result[:current_progress]).to eq(75.0)
      expect(result[:variance]).to eq(50.0)
    end

    it 'identifies changed elements' do
      result = baseline.compare_to_current

      expect(result[:element_changes].size).to eq(1)
      changed = result[:element_changes].first
      expect(changed[:element_id]).to eq('elem-2')
      expect(changed[:variance]).to eq(50)
    end
  end

  describe '#statistics_by_type' do
    let(:baseline) do
      create(:progress_baseline, :with_statistics)
    end

    it 'returns statistics grouped by element type' do
      stats = baseline.statistics_by_type

      expect(stats).to be_a(Hash)
      expect(stats['IfcWall']).to eq({ 'total' => 40, 'completed' => 10, 'progress' => 25.0 })
    end
  end

  describe '#statistics_by_status' do
    let(:baseline) do
      create(:progress_baseline, :with_statistics)
    end

    it 'returns statistics grouped by status' do
      stats = baseline.statistics_by_status

      expect(stats).to be_a(Hash)
      expect(stats['completed']).to eq(25)
      expect(stats['in_progress']).to eq(25)
    end
  end

  describe 'callbacks' do
    describe 'before_save: calculate_overall_progress' do
      it 'calculates overall_progress automatically' do
        baseline = build(:progress_baseline, total_elements: 100, completed_elements: 33, overall_progress: nil)
        baseline.save!

        expect(baseline.overall_progress).to eq(33.0)
      end
    end
  end
end
