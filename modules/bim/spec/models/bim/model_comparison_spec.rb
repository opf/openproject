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

RSpec.describe Bim::ModelComparison, type: :model do
  let(:project) { create(:project) }
  let(:model1) { create(:ifc_model, project: project, title: 'Version 1') }
  let(:model2) { create(:ifc_model, project: project, title: 'Version 2') }
  let(:user) { create(:user) }

  describe 'associations' do
    it { is_expected.to belong_to(:model1).class_name('Bim::IfcModels::IfcModel') }
    it { is_expected.to belong_to(:model2).class_name('Bim::IfcModels::IfcModel') }
    it { is_expected.to belong_to(:created_by).class_name('User').optional }
    it { is_expected.to belong_to(:approved_by).class_name('User').optional }
  end

  describe 'validations' do
    subject(:comparison) do
      described_class.new(
        model1: model1,
        model2: model2,
        comparison_type: :version,
        status: :pending
      )
    end

    it { is_expected.to validate_presence_of(:model1_id) }
    it { is_expected.to validate_presence_of(:model2_id) }
    it { is_expected.to validate_presence_of(:comparison_type) }
    it { is_expected.to validate_presence_of(:status) }

    it 'validates models are different' do
      comparison.model2 = comparison.model1
      expect(comparison).not_to be_valid
      expect(comparison.errors[:base]).to include('Cannot compare a model with itself')
    end

    it 'validates models are in same project' do
      other_project = create(:project)
      comparison.model2 = create(:ifc_model, project: other_project)

      expect(comparison).not_to be_valid
      expect(comparison.errors[:base]).to include('Models must be in the same project')
    end

    it 'validates approval data when approved' do
      comparison.status = :approved
      expect(comparison).not_to be_valid
      expect(comparison.errors[:approved_by]).to include('must be present when status is approved')
    end
  end

  describe 'enums' do
    it 'defines comparison_type enum' do
      expect(described_class.comparison_types).to eq(
        'version' => 'version',
        'baseline' => 'baseline',
        'federated' => 'federated'
      )
    end

    it 'defines status enum' do
      expect(described_class.statuses).to eq(
        'pending' => 0,
        'completed' => 1,
        'approved' => 2,
        'rejected' => 3
      )
    end
  end

  describe 'scopes' do
    let!(:comparison1) { create(:bim_model_comparison, model1: model1, model2: model2) }
    let!(:comparison2) { create(:bim_model_comparison, model1: model2, model2: model1) }
    let!(:other_comparison) { create(:bim_model_comparison) }

    describe '.for_model' do
      it 'returns comparisons involving the model' do
        results = described_class.for_model(model1)
        expect(results).to contain_exactly(comparison1, comparison2)
      end
    end

    describe '.between_models' do
      it 'returns comparisons between two specific models' do
        results = described_class.between_models(model1, model2)
        expect(results).to contain_exactly(comparison1, comparison2)
      end
    end

    describe '.with_changes' do
      before do
        comparison1.update!(added_count: 5, deleted_count: 3)
        comparison2.update!(added_count: 0, deleted_count: 0, modified_count: 0)
      end

      it 'returns only comparisons with changes' do
        results = described_class.with_changes
        expect(results).to include(comparison1)
        expect(results).not_to include(comparison2)
      end
    end

    describe '.without_changes' do
      before do
        comparison1.update!(added_count: 5, deleted_count: 3)
        comparison2.update!(added_count: 0, deleted_count: 0, modified_count: 0)
      end

      it 'returns only comparisons without changes' do
        results = described_class.without_changes
        expect(results).to include(comparison2)
        expect(results).not_to include(comparison1)
      end
    end
  end

  describe '#total_changes' do
    it 'returns sum of all change counts' do
      comparison = build(:bim_model_comparison,
                         added_count: 10,
                         deleted_count: 5,
                         modified_count: 3)

      expect(comparison.total_changes).to eq(18)
    end
  end

  describe '#has_changes?' do
    it 'returns true when there are changes' do
      comparison = build(:bim_model_comparison, added_count: 1)
      expect(comparison.has_changes?).to be true
    end

    it 'returns false when there are no changes' do
      comparison = build(:bim_model_comparison, added_count: 0, deleted_count: 0, modified_count: 0)
      expect(comparison.has_changes?).to be false
    end
  end

  describe '#total_elements' do
    it 'returns sum of all element counts' do
      comparison = build(:bim_model_comparison,
                         added_count: 10,
                         deleted_count: 5,
                         modified_count: 3,
                         unchanged_count: 100)

      expect(comparison.total_elements).to eq(118)
    end
  end

  describe '#change_percentage' do
    it 'calculates percentage of changed elements' do
      comparison = build(:bim_model_comparison,
                         added_count: 10,
                         deleted_count: 5,
                         modified_count: 5,
                         unchanged_count: 80)

      expect(comparison.change_percentage).to eq(20.0)
    end

    it 'returns 0 when no elements' do
      comparison = build(:bim_model_comparison,
                         added_count: 0,
                         deleted_count: 0,
                         modified_count: 0,
                         unchanged_count: 0)

      expect(comparison.change_percentage).to eq(0.0)
    end
  end

  describe '#approve!' do
    let(:comparison) { create(:bim_model_comparison, :completed) }

    it 'approves the comparison' do
      comparison.approve!(user: user, comment: 'Approved for construction')

      expect(comparison.status).to eq('approved')
      expect(comparison.approved_by).to eq(user)
      expect(comparison.approved_at).to be_present
      expect(comparison.status_comment).to eq('Approved for construction')
    end
  end

  describe '#reject!' do
    let(:comparison) { create(:bim_model_comparison, :completed) }

    it 'rejects the comparison' do
      comparison.reject!(user: user, comment: 'Too many structural changes')

      expect(comparison.status).to eq('rejected')
      expect(comparison.approved_by).to eq(user)
      expect(comparison.approved_at).to be_present
      expect(comparison.status_comment).to eq('Too many structural changes')
    end
  end

  describe '#complete!' do
    let(:comparison) { create(:bim_model_comparison, :pending) }

    it 'marks comparison as completed' do
      comparison.complete!(time: 2.5)

      expect(comparison.status).to eq('completed')
      expect(comparison.completed_at).to be_present
      expect(comparison.comparison_time).to eq(2.5)
    end
  end

  describe '#change_summary' do
    it 'returns summary hash' do
      comparison = create(:bim_model_comparison,
                          added_count: 10,
                          deleted_count: 5,
                          modified_count: 3,
                          unchanged_count: 82)

      summary = comparison.change_summary

      expect(summary[:added]).to eq(10)
      expect(summary[:deleted]).to eq(5)
      expect(summary[:modified]).to eq(3)
      expect(summary[:unchanged]).to eq(82)
      expect(summary[:total]).to eq(100)
      expect(summary[:percentage]).to eq(18.0)
    end
  end

  describe '#changes_by_type' do
    it 'groups changes by element type' do
      comparison = create(:bim_model_comparison,
                          changes_data: {
                            'added' => [
                              { 'element' => { 'properties' => { 'type' => 'IfcWall' } } },
                              { 'element' => { 'properties' => { 'type' => 'IfcWall' } } }
                            ],
                            'deleted' => [
                              { 'element' => { 'properties' => { 'type' => 'IfcDoor' } } }
                            ],
                            'modified' => [
                              { 'element' => { 'properties' => { 'type' => 'IfcWall' } } }
                            ]
                          })

      result = comparison.changes_by_type

      expect(result['IfcWall']).to eq({ added: 2, deleted: 0, modified: 1 })
      expect(result['IfcDoor']).to eq({ added: 0, deleted: 1, modified: 0 })
    end
  end

  describe '#generate_description' do
    it 'generates description with all change types' do
      comparison = build(:bim_model_comparison,
                         added_count: 10,
                         deleted_count: 5,
                         modified_count: 3)

      expect(comparison.generate_description).to eq('Comparison found: 10 added, 5 deleted, 3 modified elements')
    end

    it 'generates description for no changes' do
      comparison = build(:bim_model_comparison,
                         added_count: 0,
                         deleted_count: 0,
                         modified_count: 0)

      expect(comparison.generate_description).to eq('No changes detected')
    end

    it 'generates description with only some change types' do
      comparison = build(:bim_model_comparison,
                         added_count: 10,
                         deleted_count: 0,
                         modified_count: 3)

      expect(comparison.generate_description).to eq('Comparison found: 10 added, 3 modified elements')
    end
  end

  describe '#age_in_days' do
    it 'calculates age in days' do
      comparison = create(:bim_model_comparison, created_at: 5.days.ago)

      expect(comparison.age_in_days).to eq(5)
    end
  end

  describe '#stale?' do
    it 'returns true for old comparisons' do
      comparison = create(:bim_model_comparison, created_at: 40.days.ago)

      expect(comparison.stale?(30)).to be true
    end

    it 'returns false for recent comparisons' do
      comparison = create(:bim_model_comparison, created_at: 20.days.ago)

      expect(comparison.stale?(30)).to be false
    end
  end
end
