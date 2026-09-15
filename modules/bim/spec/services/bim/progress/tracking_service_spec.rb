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

RSpec.describe Bim::Progress::TrackingService do
  let(:model) { create(:ifc_model) }
  let(:user) { create(:user) }
  subject(:service) { described_class.new(ifc_model: model, user: user) }

  before do
    # Mock IFC model metadata
    allow(model).to receive(:metadata).and_return({
                                                     'elements' => {
                                                       'wall-1' => {
                                                         'properties' => { 'type' => 'IfcWall', 'name' => 'North Wall' }
                                                       },
                                                       'wall-2' => {
                                                         'properties' => { 'type' => 'IfcWall', 'name' => 'South Wall' }
                                                       }
                                                     }
                                                   })
  end

  describe '#update_element_progress' do
    context 'when element does not exist' do
      it 'creates new element progress' do
        expect do
          service.update_element_progress(element_id: 'wall-1', percent_complete: 50)
        end.to change { Bim::ElementProgress.count }.by(1)
      end

      it 'initializes from IFC metadata' do
        result = service.update_element_progress(element_id: 'wall-1', percent_complete: 50)

        progress = result.result
        expect(progress.element_type).to eq('IfcWall')
        expect(progress.element_name).to eq('North Wall')
      end
    end

    context 'when element exists' do
      let!(:existing) { create(:element_progress, ifc_model: model, element_id: 'wall-1', percent_complete: 25) }

      it 'updates existing progress' do
        result = service.update_element_progress(element_id: 'wall-1', percent_complete: 75)

        expect(result).to be_success
        expect(existing.reload.percent_complete).to eq(75)
      end

      it 'records the user' do
        service.update_element_progress(element_id: 'wall-1', percent_complete: 75)
        expect(existing.reload.updated_by).to eq(user)
      end
    end

    context 'status determination' do
      it 'sets status to planned for 0%' do
        result = service.update_element_progress(element_id: 'wall-1', percent_complete: 0)
        expect(result.result.status).to eq('planned')
      end

      it 'sets status to completed for 100%' do
        result = service.update_element_progress(element_id: 'wall-1', percent_complete: 100)
        expect(result.result.status).to eq('completed')
      end

      it 'sets status to in_progress for mid-range values' do
        result = service.update_element_progress(element_id: 'wall-1', percent_complete: 50)
        expect(result.result.status).to eq('in_progress')
      end

      it 'allows explicit status override' do
        result = service.update_element_progress(element_id: 'wall-1', percent_complete: 50, status: :on_hold)
        expect(result.result.status).to eq('on_hold')
      end
    end

    context 'date management' do
      it 'sets actual_start when status becomes in_progress' do
        result = service.update_element_progress(element_id: 'wall-1', percent_complete: 50)
        expect(result.result.actual_start).to eq(Date.current)
      end

      it 'sets actual_finish when status becomes completed' do
        result = service.update_element_progress(element_id: 'wall-1', percent_complete: 100)
        expect(result.result.actual_finish).to eq(Date.current)
      end

      it 'preserves existing actual_start' do
        create(:element_progress, :in_progress, ifc_model: model, element_id: 'wall-1', actual_start: 5.days.ago)
        result = service.update_element_progress(element_id: 'wall-1', percent_complete: 75)
        expect(result.result.actual_start).to eq(5.days.ago.to_date)
      end
    end

    context 'error handling' do
      it 'returns failure for invalid data' do
        result = service.update_element_progress(element_id: 'wall-1', percent_complete: 150)
        expect(result).to be_failure
      end
    end
  end

  describe '#bulk_update_progress' do
    let(:updates) do
      [
        { element_id: 'wall-1', percent_complete: 50 },
        { element_id: 'wall-2', percent_complete: 75 }
      ]
    end

    it 'updates multiple elements' do
      result = service.bulk_update_progress(updates)

      expect(result).to be_success
      expect(result.result.size).to eq(2)
    end

    it 'creates all elements in transaction' do
      expect do
        service.bulk_update_progress(updates)
      end.to change { Bim::ElementProgress.count }.by(2)
    end

    context 'with validation failures' do
      let(:updates) do
        [
          { element_id: 'wall-1', percent_complete: 50 },
          { element_id: 'wall-2', percent_complete: 150 } # Invalid
        ]
      end

      it 'rolls back all changes on failure' do
        expect do
          service.bulk_update_progress(updates)
        end.not_to change { Bim::ElementProgress.count }
      end

      it 'returns failure with error details' do
        result = service.bulk_update_progress(updates)

        expect(result).to be_failure
        expect(result.errors).to be_an(Array)
        expect(result.errors.first[:element_id]).to eq('wall-2')
      end
    end
  end

  describe '#sync_from_work_packages' do
    let(:wp1) { create(:work_package, done_ratio: 60) }
    let(:wp2) { create(:work_package, done_ratio: 100) }

    before do
      create(:element_progress, ifc_model: model, element_id: 'wall-1', work_package: wp1, percent_complete: 0)
      create(:element_progress, ifc_model: model, element_id: 'wall-2', work_package: wp2, percent_complete: 0)
      create(:element_progress, ifc_model: model, element_id: 'wall-3', work_package: nil, percent_complete: 0)
    end

    it 'syncs progress from linked work packages' do
      result = service.sync_from_work_packages

      expect(result).to be_success
      expect(result.result[:synced_count]).to eq(2)
    end

    it 'updates element progress to match work package' do
      service.sync_from_work_packages

      elem1 = Bim::ElementProgress.find_by(element_id: 'wall-1')
      expect(elem1.percent_complete).to eq(60)

      elem2 = Bim::ElementProgress.find_by(element_id: 'wall-2')
      expect(elem2.percent_complete).to eq(100)
    end

    it 'skips elements without work packages' do
      service.sync_from_work_packages

      elem3 = Bim::ElementProgress.find_by(element_id: 'wall-3')
      expect(elem3.percent_complete).to eq(0)
    end

    context 'when work package is closed' do
      let(:closed_status) { create(:status, is_closed: true) }
      let(:wp_closed) { create(:work_package, status: closed_status) }

      before do
        allow(wp_closed).to receive(:done_ratio).and_return(nil)
        create(:element_progress, ifc_model: model, element_id: 'wall-4', work_package: wp_closed, percent_complete: 0)
      end

      it 'sets progress to 100%' do
        service.sync_from_work_packages

        elem = Bim::ElementProgress.find_by(element_id: 'wall-4')
        expect(elem.percent_complete).to eq(100)
      end
    end
  end

  describe '#calculate_model_progress' do
    before do
      create(:element_progress, :completed, ifc_model: model)
      create(:element_progress, :in_progress, ifc_model: model, percent_complete: 50)
      create(:element_progress, :planned, ifc_model: model)
    end

    it 'calculates overall statistics' do
      stats = service.calculate_model_progress

      expect(stats[:total_elements]).to eq(3)
      expect(stats[:completed_elements]).to eq(1)
      expect(stats[:in_progress_elements]).to eq(1)
      expect(stats[:planned_elements]).to eq(1)
    end

    it 'calculates average and overall progress' do
      stats = service.calculate_model_progress

      expect(stats[:average_progress]).to eq(50.0) # (100 + 50 + 0) / 3
      expect(stats[:overall_progress]).to eq(33.33) # 1 completed / 3 total
    end

    context 'with delayed elements' do
      before do
        create(:element_progress, :delayed, ifc_model: model)
      end

      it 'counts delayed elements' do
        stats = service.calculate_model_progress
        expect(stats[:delayed_count]).to eq(1)
      end
    end

    context 'with no elements' do
      let(:empty_model) { create(:ifc_model) }
      let(:empty_service) { described_class.new(ifc_model: empty_model) }

      it 'returns zero stats' do
        stats = empty_service.calculate_model_progress

        expect(stats[:total_elements]).to eq(0)
        expect(stats[:overall_progress]).to eq(0.0)
      end
    end
  end

  describe '#compare_to_baseline' do
    let(:baseline) { create(:progress_baseline, ifc_model: model, overall_progress: 25.0) }

    before do
      # Baseline snapshot
      create(:element_progress, ifc_model: model, element_id: 'wall-1', baseline: baseline, percent_complete: 0)
      create(:element_progress, ifc_model: model, element_id: 'wall-2', baseline: baseline, percent_complete: 50)

      # Current progress
      create(:element_progress, ifc_model: model, element_id: 'wall-1', percent_complete: 50)
      create(:element_progress, ifc_model: model, element_id: 'wall-2', percent_complete: 100)
    end

    it 'compares current progress to baseline' do
      result = service.compare_to_baseline(baseline)

      expect(result).to be_a(Hash)
      expect(result[:baseline_name]).to eq(baseline.name)
      expect(result[:baseline_progress]).to eq(25.0)
      expect(result[:current_progress]).to eq(75.0)
      expect(result[:variance]).to eq(50.0)
    end

    it 'identifies changed elements' do
      result = service.compare_to_baseline(baseline)

      expect(result[:element_changes].size).to eq(2)

      change1 = result[:element_changes].find { |c| c[:element_id] == 'wall-1' }
      expect(change1[:variance]).to eq(50)

      change2 = result[:element_changes].find { |c| c[:element_id] == 'wall-2' }
      expect(change2[:variance]).to eq(50)
    end

    it 'sorts changes by absolute variance' do
      result = service.compare_to_baseline(baseline)

      variances = result[:element_changes].map { |c| c[:variance].abs }
      expect(variances).to eq(variances.sort.reverse)
    end

    it 'returns nil for nil baseline' do
      result = service.compare_to_baseline(nil)
      expect(result).to be_nil
    end
  end

  describe '#reset_all_progress' do
    before do
      create(:element_progress, ifc_model: model)
      create(:element_progress, ifc_model: model)
    end

    it 'deletes all current progress for model' do
      expect do
        service.reset_all_progress
      end.to change { Bim::ElementProgress.current.for_model(model).count }.from(2).to(0)
    end

    it 'preserves baseline progress' do
      baseline = create(:progress_baseline, ifc_model: model)
      create(:element_progress, :with_baseline, ifc_model: model, baseline: baseline)

      expect do
        service.reset_all_progress
      end.not_to change { Bim::ElementProgress.for_baseline(baseline).count }
    end

    it 'returns success result' do
      result = service.reset_all_progress
      expect(result).to be_success
    end
  end
end
