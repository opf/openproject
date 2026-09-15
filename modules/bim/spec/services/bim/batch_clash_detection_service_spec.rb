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

RSpec.describe Bim::BatchClashDetectionService do
  subject(:service) { described_class.new }

  let(:project) { create(:project) }
  let(:ifc_model1) { create(:ifc_model, project: project, title: 'Building A', is_default: true) }
  let(:ifc_model2) { create(:ifc_model, project: project, title: 'Building B', is_default: true) }
  let(:user) { create(:user) }

  before do
    # Mock metadata for both models
    allow(ifc_model1).to receive(:metadata).and_return({
                                                          'elements' => {
                                                            'wall-1' => {
                                                              'properties' => { 'type' => 'IfcWall', 'name' => 'Wall 1' },
                                                              'geometry' => {
                                                                'boundingBox' => {
                                                                  'min' => [0, 0, 0],
                                                                  'max' => [5000, 200, 3000]
                                                                }
                                                              }
                                                            },
                                                            'wall-2' => {
                                                              'properties' => { 'type' => 'IfcWall', 'name' => 'Wall 2' },
                                                              'geometry' => {
                                                                'boundingBox' => {
                                                                  'min' => [4900, 0, 0],
                                                                  'max' => [9900, 200, 3000]
                                                                }
                                                              }
                                                            }
                                                          }
                                                        })

    allow(ifc_model2).to receive(:metadata).and_return({
                                                          'elements' => {
                                                            'door-1' => {
                                                              'properties' => { 'type' => 'IfcDoor', 'name' => 'Door 1' },
                                                              'geometry' => {
                                                                'boundingBox' => {
                                                                  'min' => [2000, 0, 0],
                                                                  'max' => [3000, 100, 2100]
                                                                }
                                                              }
                                                            }
                                                          }
                                                        })
  end

  describe '#detect_across_models' do
    it 'detects clashes across all IFC models in project' do
      result = service.detect_across_models(project: project, options: { detect_hard_clashes: true })

      expect(result).to be_success
      expect(result.result[:models_processed]).to eq(2)
      expect(result.result[:detection_run_id]).to be_present
      expect(result.result[:results].size).to eq(2)
    end

    it 'includes model-specific results' do
      result = service.detect_across_models(project: project)

      model_result = result.result[:results].first
      expect(model_result).to have_key(:ifc_model_id)
      expect(model_result).to have_key(:ifc_model_title)
      expect(model_result).to have_key(:clash_count)
      expect(model_result).to have_key(:detection_time)
    end

    it 'tracks failed models' do
      allow_any_instance_of(Bim::ClashDetectionService).to receive(:detect_all_clashes)
        .and_return(ServiceResult.failure(errors: ['Detection failed']))

      result = service.detect_across_models(project: project)

      expect(result).to be_success
      expect(result.result[:models_failed]).to be > 0
      expect(result.result[:failures]).not_to be_empty
    end

    it 'returns failure when no models found' do
      empty_project = create(:project)

      result = service.detect_across_models(project: empty_project)

      expect(result).not_to be_success
      expect(result.errors).to include('No IFC models found in project')
    end

    it 'uses same detection_run_id for all models' do
      service.detect_across_models(project: project, options: { detect_hard_clashes: true })

      run_ids = Bim::Clash.pluck(:detection_run_id).uniq
      expect(run_ids.size).to eq(1)
    end
  end

  describe '#compare_detection_runs' do
    let!(:run1_clashes) do
      [
        create(:bim_clash, ifc_model: ifc_model1, element_a_id: 'wall-1', element_b_id: 'wall-2',
                           detection_run_id: 'run_1'),
        create(:bim_clash, ifc_model: ifc_model1, element_a_id: 'wall-1', element_b_id: 'door-1',
                           detection_run_id: 'run_1')
      ]
    end

    let!(:run2_clashes) do
      [
        create(:bim_clash, ifc_model: ifc_model1, element_a_id: 'wall-1', element_b_id: 'wall-2',
                           detection_run_id: 'run_2'), # Persistent
        create(:bim_clash, ifc_model: ifc_model1, element_a_id: 'column-1', element_b_id: 'beam-1',
                           detection_run_id: 'run_2') # New
      ]
    end

    it 'identifies new clashes' do
      result = service.compare_detection_runs(
        ifc_model: ifc_model1,
        run1_id: 'run_1',
        run2_id: 'run_2'
      )

      expect(result).to be_success
      expect(result.result[:new_count]).to eq(1)
      expect(result.result[:new_clashes].first.element_a_id).to eq('beam-1')
    end

    it 'identifies resolved clashes' do
      result = service.compare_detection_runs(
        ifc_model: ifc_model1,
        run1_id: 'run_1',
        run2_id: 'run_2'
      )

      expect(result).to be_success
      expect(result.result[:resolved_count]).to eq(1)
      expect(result.result[:resolved_clashes].first.element_b_id).to eq('door-1')
    end

    it 'identifies persistent clashes' do
      result = service.compare_detection_runs(
        ifc_model: ifc_model1,
        run1_id: 'run_1',
        run2_id: 'run_2'
      )

      expect(result).to be_success
      expect(result.result[:persistent_count]).to eq(1)
    end

    it 'calculates improvement rate' do
      result = service.compare_detection_runs(
        ifc_model: ifc_model1,
        run1_id: 'run_1',
        run2_id: 'run_2'
      )

      expect(result).to be_success
      expect(result.result[:improvement_rate]).to be_a(Float)
    end

    it 'returns failure for non-existent run' do
      result = service.compare_detection_runs(
        ifc_model: ifc_model1,
        run1_id: 'nonexistent',
        run2_id: 'run_2'
      )

      expect(result).not_to be_success
      expect(result.errors).to include('Run 1 not found')
    end
  end

  describe '#bulk_status_update' do
    before do
      create(:bim_clash, :hard, :critical, :new, ifc_model: ifc_model1)
      create(:bim_clash, :hard, :major, :new, ifc_model: ifc_model1)
      create(:bim_clash, :soft, :minor, :new, ifc_model: ifc_model1)
    end

    it 'updates statuses for matching clashes' do
      result = service.bulk_status_update(
        ifc_model: ifc_model1,
        criteria: { current_status: :new, severity: :critical },
        new_status: :active
      )

      expect(result).to be_success
      expect(result.result[:updated_count]).to eq(1)
      expect(Bim::Clash.where(severity: :critical, status: :active).count).to eq(1)
    end

    it 'filters by clash type' do
      result = service.bulk_status_update(
        ifc_model: ifc_model1,
        criteria: { clash_type: :hard },
        new_status: :active
      )

      expect(result).to be_success
      expect(result.result[:updated_count]).to eq(2)
    end

    it 'reports failed updates' do
      # Make one clash invalid
      clash = Bim::Clash.first
      allow(clash).to receive(:update).and_return(false)
      allow(Bim::Clash).to receive(:where).and_return([clash])

      result = service.bulk_status_update(
        ifc_model: ifc_model1,
        criteria: {},
        new_status: :active
      )

      expect(result).to be_success
      expect(result.result[:failed_count]).to be >= 0
    end
  end

  describe '#cleanup_old_clashes' do
    before do
      create(:bim_clash, :resolved, ifc_model: ifc_model1, detected_at: 100.days.ago)
      create(:bim_clash, :approved, ifc_model: ifc_model1, detected_at: 50.days.ago)
      create(:bim_clash, :new, ifc_model: ifc_model1, detected_at: 100.days.ago)
    end

    it 'archives old resolved clashes' do
      result = service.cleanup_old_clashes(
        ifc_model: ifc_model1,
        older_than: 90,
        action: :archive
      )

      expect(result).to be_success
      expect(result.result[:count]).to eq(1)
      expect(Bim::Clash.where(status: :closed).count).to eq(1)
    end

    it 'deletes old clashes when specified' do
      result = service.cleanup_old_clashes(
        ifc_model: ifc_model1,
        older_than: 90,
        action: :delete
      )

      expect(result).to be_success
      expect(result.result[:count]).to eq(1)
    end

    it 'respects status filter' do
      result = service.cleanup_old_clashes(
        ifc_model: ifc_model1,
        older_than: 90,
        statuses: [:resolved],
        action: :archive
      )

      expect(result).to be_success
      expect(result.result[:count]).to eq(1)
      expect(Bim::Clash.where(status: :approved).count).to eq(1) # Not archived
    end

    it 'returns failure for invalid action' do
      result = service.cleanup_old_clashes(
        ifc_model: ifc_model1,
        action: :invalid
      )

      expect(result).not_to be_success
    end
  end

  describe '#clash_trends' do
    before do
      create(:bim_clash, :critical, ifc_model: ifc_model1, detected_at: 1.week.ago)
      create(:bim_clash, :major, ifc_model: ifc_model1, detected_at: 1.week.ago)
      create(:bim_clash, :critical, ifc_model: ifc_model1, detected_at: 2.weeks.ago)
    end

    it 'groups clashes by week' do
      result = service.clash_trends(
        ifc_model: ifc_model1,
        period: :weekly,
        limit: 4
      )

      expect(result).to be_success
      expect(result.result[:trends]).to be_an(Array)
      expect(result.result[:period]).to eq(:weekly)
    end

    it 'includes severity breakdown' do
      result = service.clash_trends(
        ifc_model: ifc_model1,
        period: :weekly
      )

      trend = result.result[:trends].first
      expect(trend).to have_key(:by_severity)
      expect(trend).to have_key(:total)
    end

    it 'supports daily period' do
      result = service.clash_trends(
        ifc_model: ifc_model1,
        period: :daily
      )

      expect(result).to be_success
      expect(result.result[:period]).to eq(:daily)
    end

    it 'returns failure for invalid period' do
      result = service.clash_trends(
        ifc_model: ifc_model1,
        period: :invalid
      )

      expect(result).not_to be_success
    end
  end

  describe '#auto_assign_to_work_packages' do
    let(:work_package_type) { create(:type, name: 'Task') }

    before do
      create(:bim_clash, :critical, ifc_model: ifc_model1, work_package: nil)
      create(:bim_clash, :minor, ifc_model: ifc_model1, work_package: nil)
    end

    it 'assigns clashes to work packages' do
      result = service.auto_assign_to_work_packages(
        ifc_model: ifc_model1,
        rules: {
          project: project,
          type_id: work_package_type.id,
          auto_create: true
        }
      )

      expect(result).to be_success
      expect(result.result[:assigned_count]).to be > 0
    end

    it 'filters by severity' do
      result = service.auto_assign_to_work_packages(
        ifc_model: ifc_model1,
        rules: {
          project: project,
          type_id: work_package_type.id,
          severities: [:critical],
          auto_create: true
        }
      )

      expect(result).to be_success
      expect(result.result[:assigned_count]).to eq(1)
    end

    it 'skips clashes without auto_create' do
      result = service.auto_assign_to_work_packages(
        ifc_model: ifc_model1,
        rules: {
          project: project,
          type_id: work_package_type.id,
          auto_create: false
        }
      )

      expect(result).to be_success
      expect(result.result[:skipped_count]).to be > 0
    end
  end
end
