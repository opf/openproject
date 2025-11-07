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

RSpec.describe Bim::IfcModels::ValidatorService do
  let(:service) { described_class.new(ifc_file_path) }
  let(:ifc_file_path) { '/path/to/test.ifc' }

  describe '#call' do
    context 'with a valid IFC4 file' do
      before do
        allow(File).to receive(:exist?).with(ifc_file_path).and_return(true)
        allow(File).to receive(:size).with(ifc_file_path).and_return(1024 * 1024) # 1MB
        allow(service).to receive(:detect_ifc_version).and_return('IFC4')
        allow(service).to receive(:validate_schema).and_return([])
        allow(service).to receive(:analyze_complexity).and_return({
                                                                     entity_count: 50_000,
                                                                     geometry_count: 12_000
                                                                   })
      end

      it 'returns valid result with metadata' do
        result = service.call

        expect(result[:valid]).to be true
        expect(result[:ifc_version]).to eq 'IFC4'
        expect(result[:schema_errors]).to be_empty
        expect(result[:entity_count]).to eq 50_000
        expect(result[:file_size]).to eq 1024 * 1024
      end

      it 'estimates conversion time based on complexity' do
        result = service.call

        expect(result[:estimated_conversion_time]).to be_a(Numeric)
        expect(result[:estimated_conversion_time]).to be > 0
      end
    end

    context 'with a corrupted file' do
      before do
        allow(File).to receive(:exist?).with(ifc_file_path).and_return(true)
        allow(File).to receive(:size).with(ifc_file_path).and_return(1024)
        allow(service).to receive(:detect_ifc_version).and_return(nil)
      end

      it 'returns invalid result' do
        result = service.call

        expect(result[:valid]).to be false
        expect(result[:schema_errors]).to include(/Unable to detect IFC version/)
      end
    end

    context 'with schema validation errors' do
      before do
        allow(File).to receive(:exist?).with(ifc_file_path).and_return(true)
        allow(File).to receive(:size).with(ifc_file_path).and_return(1024 * 1024)
        allow(service).to receive(:detect_ifc_version).and_return('IFC2x3')
        allow(service).to receive(:validate_schema).and_return([
                                                                  'Invalid entity reference',
                                                                  'Missing required attribute'
                                                                ])
      end

      it 'returns errors but marks as valid with warnings' do
        result = service.call

        expect(result[:valid]).to be true # Can still attempt conversion
        expect(result[:schema_errors]).not_to be_empty
        expect(result[:schema_errors].size).to eq 2
      end
    end

    context 'when file does not exist' do
      before do
        allow(File).to receive(:exist?).with(ifc_file_path).and_return(false)
      end

      it 'returns invalid result' do
        result = service.call

        expect(result[:valid]).to be false
        expect(result[:schema_errors]).to include(/File not found/)
      end
    end

    context 'with a very large file' do
      before do
        allow(File).to receive(:exist?).with(ifc_file_path).and_return(true)
        allow(File).to receive(:size).with(ifc_file_path).and_return(2 * 1024 * 1024 * 1024) # 2GB
        allow(service).to receive(:detect_ifc_version).and_return('IFC4')
        allow(service).to receive(:validate_schema).and_return([])
        allow(service).to receive(:analyze_complexity).and_return({
                                                                     entity_count: 500_000,
                                                                     geometry_count: 120_000
                                                                   })
      end

      it 'includes warning about large file size' do
        result = service.call

        expect(result[:valid]).to be true
        expect(result[:warnings]).to include(/Large file detected/)
        expect(result[:estimated_conversion_time]).to be > 300 # More than 5 minutes
      end
    end
  end

  describe '#detect_ifc_version' do
    it 'detects IFC4 from header' do
      allow(File).to receive(:read).with(ifc_file_path, 1024).and_return(
        "ISO-10303-21;\nHEADER;\nFILE_SCHEMA(('IFC4'));\nENDSEC;\nDATA;\n"
      )

      version = service.send(:detect_ifc_version)
      expect(version).to eq 'IFC4'
    end

    it 'detects IFC2x3 from header' do
      allow(File).to receive(:read).with(ifc_file_path, 1024).and_return(
        "ISO-10303-21;\nHEADER;\nFILE_SCHEMA(('IFC2X3'));\nENDSEC;\nDATA;\n"
      )

      version = service.send(:detect_ifc_version)
      expect(version).to eq 'IFC2x3'
    end

    it 'returns nil for unrecognized format' do
      allow(File).to receive(:read).with(ifc_file_path, 1024).and_return("INVALID DATA")

      version = service.send(:detect_ifc_version)
      expect(version).to be_nil
    end
  end

  describe '#calculate_checksum' do
    it 'calculates SHA256 checksum' do
      allow(Digest::SHA256).to receive(:file).with(ifc_file_path).and_return(
        double(hexdigest: 'abc123def456')
      )

      checksum = service.send(:calculate_checksum)
      expect(checksum).to eq 'abc123def456'
    end
  end

  describe '#estimate_conversion_time' do
    it 'estimates based on entity count' do
      time = service.send(:estimate_conversion_time, 50_000)
      expect(time).to be_between(60, 300) # 1-5 minutes for 50k entities
    end

    it 'scales with entity count' do
      small_time = service.send(:estimate_conversion_time, 10_000)
      large_time = service.send(:estimate_conversion_time, 100_000)

      expect(large_time).to be > small_time
    end
  end
end
