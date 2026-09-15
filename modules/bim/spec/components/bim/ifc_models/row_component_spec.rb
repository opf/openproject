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

RSpec.describe Bim::IfcModels::RowComponent, type: :component do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:ifc_model) do
    create(:ifc_model,
           title: 'Test Model',
           project: project,
           uploader: user,
           conversion_status: conversion_status,
           conversion_progress: conversion_progress,
           conversion_stage: conversion_stage,
           conversion_logs: conversion_logs,
           conversion_error_message: error_message)
  end
  let(:conversion_status) { :processing }
  let(:conversion_progress) { 0 }
  let(:conversion_stage) { nil }
  let(:conversion_logs) { [] }
  let(:error_message) { nil }

  subject(:component) { described_class.new(model: ifc_model) }
  let(:rendered) { render_inline(component) }

  before do
    login_as(user)
    allow(User).to receive(:current).and_return(user)
  end

  describe '#processing' do
    context 'when model is pending conversion' do
      let(:conversion_status) { :pending }
      let(:conversion_progress) { 0 }

      it 'shows pending status' do
        expect(rendered.to_html).to include('conversion_status.pending')
        expect(rendered.to_html).not_to include('progress-bar')
      end
    end

    context 'when model is processing with no progress' do
      let(:conversion_status) { :processing }
      let(:conversion_progress) { 0 }

      it 'shows processing status with 0% progress' do
        expect(rendered.to_html).to include('conversion_status.processing')
        expect(rendered.to_html).to include('progress-bar')
        expect(rendered.to_html).to include('0%')
      end
    end

    context 'when model is processing at validation stage' do
      let(:conversion_status) { :processing }
      let(:conversion_progress) { 5 }
      let(:conversion_stage) { 'validation' }

      it 'shows validation stage with 5% progress' do
        expect(rendered.to_html).to include('conversion_status.processing')
        expect(rendered.to_html).to include('progress-bar')
        expect(rendered.to_html).to include('5%')
        expect(rendered.to_html).to include('Validation')
      end
    end

    context 'when model is processing at IFC to DAE stage' do
      let(:conversion_status) { :processing }
      let(:conversion_progress) { 25 }
      let(:conversion_stage) { 'ifc_to_dae' }

      it 'shows IFC to DAE stage with 25% progress' do
        expect(rendered.to_html).to include('progress-bar')
        expect(rendered.to_html).to include('25%')
        expect(rendered.to_html).to include('IFC to DAE')
      end
    end

    context 'when model is processing at DAE to glTF stage' do
      let(:conversion_status) { :processing }
      let(:conversion_progress) { 45 }
      let(:conversion_stage) { 'dae_to_gltf' }

      it 'shows DAE to glTF stage with 45% progress' do
        expect(rendered.to_html).to include('45%')
        expect(rendered.to_html).to include('DAE to glTF')
      end
    end

    context 'when model is processing at glTF to XKT stage' do
      let(:conversion_status) { :processing }
      let(:conversion_progress) { 65 }
      let(:conversion_stage) { 'gltf_to_xkt' }

      it 'shows glTF to XKT stage with 65% progress' do
        expect(rendered.to_html).to include('65%')
        expect(rendered.to_html).to include('glTF to XKT')
      end
    end

    context 'when model is processing at metadata extraction stage' do
      let(:conversion_status) { :processing }
      let(:conversion_progress) { 95 }
      let(:conversion_stage) { 'enhanced_metadata' }

      it 'shows metadata extraction stage with 95% progress' do
        expect(rendered.to_html).to include('95%')
        expect(rendered.to_html).to include('Metadata extraction')
      end
    end

    context 'when model conversion is completed' do
      let(:conversion_status) { :completed }
      let(:conversion_progress) { 100 }

      it 'shows completed status without progress bar' do
        expect(rendered.to_html).to include('conversion_status.completed')
        expect(rendered.to_html).not_to include('progress-bar')
      end
    end

    context 'when model conversion failed with error' do
      let(:conversion_status) { :error }
      let(:error_message) { 'IFC validation failed: Invalid STEP format' }

      it 'shows error status and message' do
        expect(rendered.to_html).to include('conversion_status.error')
        expect(rendered.to_html).to include('Invalid STEP format')
        expect(rendered.to_html).to include('ifc-models--conversion-status-error')
      end
    end

    context 'when model has validation warnings in logs' do
      let(:conversion_status) { :processing }
      let(:conversion_progress) { 25 }
      let(:conversion_logs) do
        [
          {
            'stage' => 'validation',
            'level' => 'warning',
            'message' => 'Large file detected (500MB)',
            'timestamp' => Time.current.iso8601
          },
          {
            'stage' => 'validation',
            'level' => 'warning',
            'message' => 'Complex model detected (150000 entities)',
            'timestamp' => Time.current.iso8601
          }
        ]
      end

      it 'displays warning count' do
        expect(rendered.to_html).to include('2 warnings')
      end

      it 'includes warnings in expandable section' do
        expect(rendered.to_html).to include('Large file detected')
        expect(rendered.to_html).to include('Complex model detected')
      end
    end

    context 'when model has conversion errors in logs' do
      let(:conversion_status) { :error }
      let(:conversion_logs) do
        [
          {
            'stage' => 'ifc_to_dae',
            'level' => 'error',
            'message' => 'Failed IFC to DAE: IfcConvert exited with status 1',
            'timestamp' => Time.current.iso8601
          }
        ]
      end

      it 'displays error information' do
        expect(rendered.to_html).to include('Failed IFC to DAE')
      end
    end
  end

  describe '#progress_percentage' do
    context 'with conversion progress' do
      let(:conversion_progress) { 45 }

      it 'returns the progress percentage' do
        expect(component.progress_percentage).to eq(45)
      end
    end

    context 'with nil conversion progress' do
      let(:conversion_progress) { nil }

      it 'returns 0' do
        expect(component.progress_percentage).to eq(0)
      end
    end
  end

  describe '#stage_name' do
    context 'with validation stage' do
      let(:conversion_stage) { 'validation' }

      it 'returns humanized stage name' do
        expect(component.stage_name).to eq('Validation')
      end
    end

    context 'with ifc_to_dae stage' do
      let(:conversion_stage) { 'ifc_to_dae' }

      it 'returns humanized stage name' do
        expect(component.stage_name).to eq('IFC to DAE')
      end
    end

    context 'with nil stage' do
      let(:conversion_stage) { nil }

      it 'returns empty string' do
        expect(component.stage_name).to eq('')
      end
    end
  end

  describe '#warnings' do
    context 'with warning logs' do
      let(:conversion_logs) do
        [
          { 'level' => 'info', 'message' => 'Starting conversion' },
          { 'level' => 'warning', 'message' => 'Warning 1' },
          { 'level' => 'warning', 'message' => 'Warning 2' },
          { 'level' => 'error', 'message' => 'Error 1' }
        ]
      end

      it 'returns only warning logs' do
        warnings = component.warnings
        expect(warnings.count).to eq(2)
        expect(warnings.first['message']).to eq('Warning 1')
      end
    end

    context 'with no warnings' do
      let(:conversion_logs) do
        [{ 'level' => 'info', 'message' => 'Starting conversion' }]
      end

      it 'returns empty array' do
        expect(component.warnings).to be_empty
      end
    end
  end

  describe '#has_warnings?' do
    context 'with warnings' do
      let(:conversion_logs) do
        [{ 'level' => 'warning', 'message' => 'Warning' }]
      end

      it 'returns true' do
        expect(component).to be_has_warnings
      end
    end

    context 'without warnings' do
      let(:conversion_logs) { [] }

      it 'returns false' do
        expect(component).not_to be_has_warnings
      end
    end
  end
end
