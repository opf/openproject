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

RSpec.describe Bim::ClashGroupingService do
  let(:ifc_model) { create(:ifc_model, title: 'Test Building') }
  subject(:service) { described_class.new(ifc_model: ifc_model) }

  before do
    allow(ifc_model).to receive(:metadata).and_return({
                                                         'elements' => {
                                                           'wall-1' => {
                                                             'properties' => { 'type' => 'IfcWall', 'name' => 'Wall 1' },
                                                             'spatial_structure' => {
                                                               'building' => 'Building A',
                                                               'storey' => 'Level 1',
                                                               'space' => 'Room 101'
                                                             }
                                                           },
                                                           'wall-2' => {
                                                             'properties' => { 'type' => 'IfcWall', 'name' => 'Wall 2' },
                                                             'spatial_structure' => {
                                                               'building' => 'Building A',
                                                               'storey' => 'Level 1',
                                                               'space' => 'Room 102'
                                                             }
                                                           },
                                                           'door-1' => {
                                                             'properties' => { 'type' => 'IfcDoor', 'name' => 'Door 1' },
                                                             'spatial_structure' => {
                                                               'building' => 'Building A',
                                                               'storey' => 'Level 1',
                                                               'space' => 'Room 101'
                                                             }
                                                           },
                                                           'column-1' => {
                                                             'properties' => { 'type' => 'IfcColumn', 'name' => 'Column 1' },
                                                             'spatial_structure' => {
                                                               'building' => 'Building A',
                                                               'storey' => 'Level 2',
                                                               'space' => nil
                                                             }
                                                           }
                                                         }
                                                       })
  end

  describe '#group_by_element' do
    before do
      # wall-1 appears in 3 clashes (problematic element)
      create(:bim_clash, :active, ifc_model: ifc_model, element_a_id: 'wall-1', element_b_id: 'wall-2')
      create(:bim_clash, :active, ifc_model: ifc_model, element_a_id: 'door-1', element_b_id: 'wall-1')
      create(:bim_clash, :active, ifc_model: ifc_model, element_a_id: 'column-1', element_b_id: 'wall-1')

      # wall-2 appears in 1 clash
      # Other elements appear in fewer clashes
    end

    it 'groups clashes by element involvement' do
      result = service.group_by_element(min_clash_count: 2)

      expect(result).to be_success
      expect(result.result[:total_groups]).to be >= 1
    end

    it 'filters by minimum clash count' do
      result = service.group_by_element(min_clash_count: 3)

      expect(result).to be_success
      groups = result.result[:groups]
      expect(groups.size).to eq(1)
      expect(groups.first[:element_id]).to eq('wall-1')
      expect(groups.first[:clash_count]).to eq(3)
    end

    it 'includes element metadata' do
      result = service.group_by_element(min_clash_count: 2)

      group = result.result[:groups].first
      expect(group).to have_key(:element_id)
      expect(group).to have_key(:element_name)
      expect(group).to have_key(:clash_count)
      expect(group).to have_key(:clashes)
    end

    it 'includes severity breakdown' do
      result = service.group_by_element(min_clash_count: 2)

      group = result.result[:groups].first
      expect(group).to have_key(:severity_breakdown)
      expect(group).to have_key(:type_breakdown)
    end

    it 'sorts by clash count descending' do
      result = service.group_by_element(min_clash_count: 1)

      groups = result.result[:groups]
      counts = groups.map { |g| g[:clash_count] }
      expect(counts).to eq(counts.sort.reverse)
    end

    it 'includes summary statistics' do
      result = service.group_by_element

      expect(result.result[:summary]).to have_key(:most_problematic_element)
      expect(result.result[:summary]).to have_key(:average_clashes_per_element)
    end
  end

  describe '#group_by_spatial_proximity' do
    before do
      create(:bim_clash, :active, ifc_model: ifc_model,
                         element_a_id: 'wall-1',
                         element_b_id: 'wall-2',
                         clash_point: { x: 1000.0, y: 500.0, z: 1500.0 })

      create(:bim_clash, :active, ifc_model: ifc_model,
                         element_a_id: 'door-1',
                         element_b_id: 'wall-1',
                         clash_point: { x: 1100.0, y: 520.0, z: 1480.0 })

      create(:bim_clash, :active, ifc_model: ifc_model,
                         element_a_id: 'column-1',
                         element_b_id: 'wall-2',
                         clash_point: { x: 10000.0, y: 500.0, z: 1500.0 })
    end

    it 'groups clashes by spatial proximity' do
      result = service.group_by_spatial_proximity(distance_threshold: 5000.0)

      expect(result).to be_success
      expect(result.result[:total_clusters]).to be >= 1
    end

    it 'uses distance threshold for clustering' do
      result = service.group_by_spatial_proximity(distance_threshold: 200.0)

      expect(result).to be_success
      clusters = result.result[:clusters]
      # Clashes at (1000, 500, 1500) and (1100, 520, 1480) should be in same cluster
      # Clash at (10000, 500, 1500) should be in different cluster
      expect(clusters.size).to eq(2)
    end

    it 'includes cluster metadata' do
      result = service.group_by_spatial_proximity

      cluster = result.result[:clusters].first
      expect(cluster).to have_key(:cluster_id)
      expect(cluster).to have_key(:clash_count)
      expect(cluster).to have_key(:centroid)
      expect(cluster).to have_key(:bounding_box)
      expect(cluster).to have_key(:severity_breakdown)
    end

    it 'calculates cluster centroids' do
      result = service.group_by_spatial_proximity(distance_threshold: 200.0)

      cluster = result.result[:clusters].first
      expect(cluster[:centroid]).to have_key(:x)
      expect(cluster[:centroid]).to have_key(:y)
      expect(cluster[:centroid]).to have_key(:z)
    end

    it 'calculates bounding boxes' do
      result = service.group_by_spatial_proximity

      cluster = result.result[:clusters].first
      expect(cluster[:bounding_box]).to have_key(:min)
      expect(cluster[:bounding_box]).to have_key(:max)
    end

    it 'sorts clusters by size' do
      result = service.group_by_spatial_proximity

      clusters = result.result[:clusters]
      counts = clusters.map { |c| c[:clash_count] }
      expect(counts).to eq(counts.sort.reverse)
    end

    it 'returns failure for no clashes with spatial data' do
      Bim::Clash.update_all(clash_point: nil)

      result = service.group_by_spatial_proximity

      expect(result).not_to be_success
      expect(result.errors).to include('No clashes with spatial data')
    end
  end

  describe '#group_by_type_pattern' do
    before do
      # Create clashes with different type patterns
      create(:bim_clash, :active, ifc_model: ifc_model, element_a_id: 'wall-1', element_b_id: 'wall-2')
      create(:bim_clash, :active, ifc_model: ifc_model, element_a_id: 'door-1', element_b_id: 'wall-1')
      create(:bim_clash, :active, ifc_model: ifc_model, element_a_id: 'door-1', element_b_id: 'wall-2')
      create(:bim_clash, :active, ifc_model: ifc_model, element_a_id: 'column-1', element_b_id: 'wall-1')
    end

    it 'groups clashes by element type patterns' do
      result = service.group_by_type_pattern

      expect(result).to be_success
      expect(result.result[:total_type_patterns]).to be >= 1
    end

    it 'normalizes type pairs (A-B same as B-A)' do
      result = service.group_by_type_pattern

      groups = result.result[:groups]
      pair_keys = groups.map { |g| g[:type_pair] }

      # Should have normalized pairs
      expect(pair_keys).to include('IfcDoor vs IfcWall')
      expect(pair_keys).not_to include('IfcWall vs IfcDoor')
    end

    it 'includes type pattern metadata' do
      result = service.group_by_type_pattern

      group = result.result[:groups].first
      expect(group).to have_key(:type_pair)
      expect(group).to have_key(:type_a)
      expect(group).to have_key(:type_b)
      expect(group).to have_key(:clash_count)
      expect(group).to have_key(:severity_breakdown)
      expect(group).to have_key(:average_severity_score)
    end

    it 'identifies most common clash pattern' do
      result = service.group_by_type_pattern

      expect(result.result[:summary][:most_common_pattern]).to be_present
    end

    it 'sorts by clash count' do
      result = service.group_by_type_pattern

      groups = result.result[:groups]
      counts = groups.map { |g| g[:clash_count] }
      expect(counts).to eq(counts.sort.reverse)
    end
  end

  describe '#group_by_detection_run' do
    before do
      create(:bim_clash, ifc_model: ifc_model, detection_run_id: 'run_1', detected_at: 1.week.ago)
      create(:bim_clash, ifc_model: ifc_model, detection_run_id: 'run_1', detected_at: 1.week.ago)
      create(:bim_clash, ifc_model: ifc_model, detection_run_id: 'run_2', detected_at: 1.day.ago)
    end

    it 'groups clashes by detection run' do
      result = service.group_by_detection_run

      expect(result).to be_success
      expect(result.result[:total_runs]).to eq(2)
    end

    it 'includes run metadata' do
      result = service.group_by_detection_run

      group = result.result[:groups].first
      expect(group).to have_key(:detection_run_id)
      expect(group).to have_key(:run_date)
      expect(group).to have_key(:clash_count)
      expect(group).to have_key(:severity_breakdown)
      expect(group).to have_key(:status_breakdown)
    end

    it 'orders by run date descending' do
      result = service.group_by_detection_run

      groups = result.result[:groups]
      expect(groups.first[:detection_run_id]).to eq('run_2')
      expect(groups.last[:detection_run_id]).to eq('run_1')
    end

    it 'identifies latest run' do
      result = service.group_by_detection_run

      expect(result.result[:summary][:latest_run][:detection_run_id]).to eq('run_2')
    end
  end

  describe '#group_by_spatial_structure' do
    before do
      create(:bim_clash, :active, ifc_model: ifc_model, element_a_id: 'wall-1', element_b_id: 'wall-2')
      create(:bim_clash, :active, ifc_model: ifc_model, element_a_id: 'door-1', element_b_id: 'wall-1')
      create(:bim_clash, :active, ifc_model: ifc_model, element_a_id: 'column-1', element_b_id: 'wall-2')
    end

    it 'groups by building storey' do
      result = service.group_by_spatial_structure(level: :storey)

      expect(result).to be_success
      expect(result.result[:level]).to eq(:storey)
      expect(result.result[:total_locations]).to be >= 1
    end

    it 'groups by building level' do
      result = service.group_by_spatial_structure(level: :building)

      expect(result).to be_success
      groups = result.result[:groups]
      expect(groups).not_to be_empty
      expect(groups.first[:location]).to eq('Building A')
    end

    it 'groups by space' do
      result = service.group_by_spatial_structure(level: :space)

      expect(result).to be_success
      groups = result.result[:groups]
      expect(groups).not_to be_empty
    end

    it 'includes location metadata' do
      result = service.group_by_spatial_structure(level: :storey)

      group = result.result[:groups].first
      expect(group).to have_key(:location)
      expect(group).to have_key(:level)
      expect(group).to have_key(:clash_count)
      expect(group).to have_key(:severity_breakdown)
      expect(group).to have_key(:type_breakdown)
    end

    it 'sorts by clash count' do
      result = service.group_by_spatial_structure

      groups = result.result[:groups]
      counts = groups.map { |g| g[:clash_count] }
      expect(counts).to eq(counts.sort.reverse)
    end

    it 'identifies most problematic location' do
      result = service.group_by_spatial_structure(level: :storey)

      expect(result.result[:summary][:most_problematic_location]).to be_present
    end
  end
end
