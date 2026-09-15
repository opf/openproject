# frozen_string_literal: true

# -- copyright
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
# ++

require 'rails_helper'

RSpec.describe Bim::IfcModels::ViewConverterService do
  let(:user) { create(:admin) }
  let(:project) { create(:project) }
  let(:ifc_model) { create(:ifc_model, project:, uploader: user) }
  let(:service) { described_class.new(ifc_model) }
  let(:ifc_file_path) { ifc_model.ifc_attachment.diskfile.path }

  before do
    # Mock external command availability
    allow(described_class).to receive(:available?).and_return(true)
    allow(described_class).to receive(:available_commands).and_return(
      described_class::PIPELINE_COMMANDS
    )
  end

  describe '#call' do
    context 'with successful conversion' do
      before do
        # Mock all stages to succeed
        allow(service).to receive(:stage_validation).and_return(true)
        allow(service).to receive(:convert_to_collada).and_return('/tmp/model.dae')
        allow(service).to receive(:convert_to_gltf).and_return('/tmp/model.gltf')
        allow(service).to receive(:convert_to_xkt).and_return('/tmp/model.xkt')
        allow(service).to receive(:stage_enhanced_metadata).and_return(true)
        allow(service).to receive(:save_xkt).and_return(true)
      end

      it 'completes all 6 stages' do
        result = service.call

        expect(result).to be_success
        expect(ifc_model.reload.conversion_status).to eq 'completed'
        expect(ifc_model.conversion_progress).to eq 100
      end

      it 'updates progress through all stages' do
        service.call

        expect(ifc_model.reload.conversion_stage).to eq 'enhanced_metadata'
        expect(ifc_model.conversion_progress).to be_between(95, 100)
      end

      it 'logs each stage completion' do
        service.call

        logs = ifc_model.reload.conversion_logs
        expect(logs).to be_an(Array)
        expect(logs.size).to be >= 6

        # Check that all stage names are logged
        stage_names = logs.map { |log| log['stage'] }
        expect(stage_names).to include('validation', 'ifc_to_dae', 'dae_to_gltf',
                                       'gltf_to_xkt', 'enhanced_metadata')
      end

      it 'clears previous error message on success' do
        ifc_model.update!(conversion_error_message: 'Previous error')

        service.call

        expect(ifc_model.reload.conversion_error_message).to be_nil
      end
    end

    context 'with validation failure' do
      before do
        # Mock validation to fail
        validator_result = {
          valid: false,
          schema_errors: ['Invalid IFC format'],
          warnings: []
        }
        allow_any_instance_of(Bim::IfcModels::ValidatorService)
          .to receive(:call).and_return(validator_result)
      end

      it 'fails at validation stage' do
        result = service.call

        expect(result).not_to be_success
        expect(ifc_model.reload.conversion_status).to eq 'error'
        expect(ifc_model.conversion_stage).to eq 'validation'
      end

      it 'logs validation error' do
        service.call

        logs = ifc_model.reload.conversion_logs
        error_log = logs.find { |log| log['level'] == 'error' && log['stage'] == 'validation' }

        expect(error_log).to be_present
        expect(error_log['message']).to include('Invalid IFC format')
      end

      it 'does not proceed to subsequent stages' do
        service.call

        # Ensure DAE conversion was never called
        expect(service).not_to have_received(:convert_to_collada)
      end
    end

    context 'with conversion stage failure' do
      before do
        allow(service).to receive(:stage_validation).and_return(true)
        allow(service).to receive(:convert_to_collada).and_raise(
          StandardError.new('IfcConvert failed: Invalid geometry')
        )
      end

      it 'marks conversion as error' do
        result = service.call

        expect(result).not_to be_success
        expect(ifc_model.reload.conversion_status).to eq 'error'
        expect(ifc_model.conversion_stage).to eq 'ifc_to_dae'
      end

      it 'stores error message' do
        service.call

        expect(ifc_model.reload.conversion_error_message).to include('IfcConvert failed')
      end

      it 'logs error details' do
        service.call

        logs = ifc_model.reload.conversion_logs
        error_log = logs.find { |log| log['level'] == 'error' && log['stage'] == 'ifc_to_dae' }

        expect(error_log).to be_present
        expect(error_log['message']).to include('IfcConvert failed')
      end
    end

    context 'with metadata extraction failure' do
      before do
        allow(service).to receive(:stage_validation).and_return(true)
        allow(service).to receive(:convert_to_collada).and_return('/tmp/model.dae')
        allow(service).to receive(:convert_to_gltf).and_return('/tmp/model.gltf')
        allow(service).to receive(:convert_to_xkt).and_return('/tmp/model.xkt')
        allow(service).to receive(:save_xkt).and_return(true)

        # Mock metadata extraction to fail
        allow_any_instance_of(Bim::IfcModels::MetadataExtractorService)
          .to receive(:call).and_return(ServiceResult.failure(errors: ['Python script failed']))
      end

      it 'logs warning but continues conversion' do
        result = service.call

        # Conversion should still succeed even if metadata extraction fails
        expect(result).to be_success
        expect(ifc_model.reload.conversion_status).to eq 'completed'

        # But there should be a warning in logs
        logs = ifc_model.conversion_logs
        warning_log = logs.find { |log| log['level'] == 'warning' && log['stage'] == 'enhanced_metadata' }
        expect(warning_log).to be_present
      end
    end
  end

  describe 'progress tracking' do
    before do
      allow(service).to receive(:stage_validation).and_return(true)
      allow(service).to receive(:convert_to_collada).and_return('/tmp/model.dae')
      allow(service).to receive(:convert_to_gltf).and_return('/tmp/model.gltf')
      allow(service).to receive(:convert_to_xkt).and_return('/tmp/model.xkt')
      allow(service).to receive(:stage_enhanced_metadata).and_return(true)
      allow(service).to receive(:save_xkt).and_return(true)
    end

    it 'increments progress through stages' do
      progress_values = []

      allow(ifc_model).to receive(:update!) do |attrs|
        progress_values << attrs[:conversion_progress] if attrs[:conversion_progress]
        ifc_model.assign_attributes(attrs)
      end

      service.call

      # Progress should increase monotonically
      expect(progress_values).to eq(progress_values.sort)
      expect(progress_values.last).to eq(100)
    end

    it 'updates stage name as conversion progresses' do
      stage_names = []

      allow(ifc_model).to receive(:update!) do |attrs|
        stage_names << attrs[:conversion_stage] if attrs[:conversion_stage]
        ifc_model.assign_attributes(attrs)
      end

      service.call

      expect(stage_names).to include('validation', 'ifc_to_dae', 'dae_to_gltf',
                                     'gltf_to_xkt', 'enhanced_metadata')
    end
  end

  describe 'stage execution order' do
    it 'executes stages in correct order' do
      execution_order = []

      allow(service).to receive(:stage_validation) do
        execution_order << :validation
        true
      end
      allow(service).to receive(:convert_to_collada) do
        execution_order << :ifc_to_dae
        '/tmp/model.dae'
      end
      allow(service).to receive(:convert_to_gltf) do
        execution_order << :dae_to_gltf
        '/tmp/model.gltf'
      end
      allow(service).to receive(:convert_to_xkt) do
        execution_order << :gltf_to_xkt
        '/tmp/model.xkt'
      end
      allow(service).to receive(:stage_enhanced_metadata) do
        execution_order << :enhanced_metadata
        true
      end
      allow(service).to receive(:save_xkt).and_return(true)

      service.call

      expect(execution_order).to eq([
        :validation,
        :ifc_to_dae,
        :dae_to_gltf,
        :gltf_to_xkt,
        :enhanced_metadata
      ])
    end
  end

  describe '#stage_validation' do
    it 'calls ValidatorService with IFC file path' do
      validator = instance_double(Bim::IfcModels::ValidatorService)
      expect(Bim::IfcModels::ValidatorService).to receive(:new).with(kind_of(String)).and_return(validator)
      expect(validator).to receive(:call).and_return({ valid: true, schema_errors: [], warnings: [] })

      service.send(:stage_validation)
    end

    it 'logs validation warnings if present' do
      validator_result = {
        valid: true,
        schema_errors: [],
        warnings: ['Large file detected (500MB)']
      }
      allow_any_instance_of(Bim::IfcModels::ValidatorService)
        .to receive(:call).and_return(validator_result)

      service.send(:stage_validation)

      logs = ifc_model.reload.conversion_logs
      warning_log = logs.find { |log| log['level'] == 'warning' && log['stage'] == 'validation' }
      expect(warning_log['message']).to include('Large file detected')
    end
  end

  describe '#stage_enhanced_metadata' do
    it 'calls MetadataExtractorService' do
      extractor = instance_double(Bim::IfcModels::MetadataExtractorService)
      expect(Bim::IfcModels::MetadataExtractorService).to receive(:new).with(ifc_model).and_return(extractor)
      expect(extractor).to receive(:call).and_return(ServiceResult.success)

      service.send(:stage_enhanced_metadata)
    end

    it 'does not fail conversion if metadata extraction fails' do
      allow_any_instance_of(Bim::IfcModels::MetadataExtractorService)
        .to receive(:call).and_return(ServiceResult.failure(errors: ['Extraction failed']))

      expect { service.send(:stage_enhanced_metadata) }.not_to raise_error
    end
  end
end
