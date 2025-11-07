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

RSpec.describe Bim::Measurement, type: :model do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:ifc_model) { create(:ifc_model, project: project) }

  subject(:measurement) do
    described_class.new(
      ifc_model: ifc_model,
      user: user,
      measurement_type: 'distance',
      value: 10.5,
      unit: 'm',
      points: [[0, 0, 0], [10, 0, 0]]
    )
  end

  describe 'associations' do
    it { is_expected.to belong_to(:ifc_model) }
    it { is_expected.to belong_to(:user).optional }
  end

  describe 'validations' do
    context 'with valid attributes' do
      it 'is valid' do
        expect(measurement).to be_valid
      end
    end

    describe 'measurement_type' do
      it 'requires measurement_type to be present' do
        measurement.measurement_type = nil
        expect(measurement).not_to be_valid
      end

      it 'accepts valid measurement types' do
        %w[distance area volume angle elevation].each do |type|
          measurement.measurement_type = type
          measurement.points = [[0, 0, 0], [1, 1, 1]]
          expect(measurement).to be_valid
        end
      end

      it 'rejects invalid measurement types' do
        measurement.measurement_type = 'invalid'
        expect(measurement).not_to be_valid
      end
    end

    describe 'value' do
      it 'requires value to be present' do
        measurement.value = nil
        expect(measurement).not_to be_valid
      end

      it 'accepts positive values' do
        measurement.value = 100.5
        expect(measurement).to be_valid
      end

      it 'accepts zero' do
        measurement.value = 0
        expect(measurement).to be_valid
      end

      it 'rejects negative values' do
        measurement.value = -10
        expect(measurement).not_to be_valid
      end
    end

    describe 'unit' do
      it 'requires unit to be present' do
        measurement.unit = nil
        expect(measurement).not_to be_valid
      end

      it 'validates unit matches measurement type' do
        measurement.measurement_type = 'distance'
        measurement.unit = 'm²'
        expect(measurement).not_to be_valid
        expect(measurement.errors[:unit]).to include(/must be one of/)
      end

      it 'accepts valid units for distance' do
        measurement.measurement_type = 'distance'
        %w[m cm mm ft in].each do |unit|
          measurement.unit = unit
          expect(measurement).to be_valid
        end
      end

      it 'accepts valid units for area' do
        measurement.measurement_type = 'area'
        measurement.points = [[0, 0, 0], [1, 0, 0], [0, 0, 1]]
        %w[m² cm² mm² ft² in²].each do |unit|
          measurement.unit = unit
          expect(measurement).to be_valid
        end
      end

      it 'accepts valid units for angle' do
        measurement.measurement_type = 'angle'
        measurement.points = [[0, 0, 0], [1, 0, 0], [0, 1, 0]]
        %w[degrees radians].each do |unit|
          measurement.unit = unit
          expect(measurement).to be_valid
        end
      end
    end

    describe 'color' do
      it 'accepts valid hex colors' do
        measurement.color = '#FF0000'
        expect(measurement).to be_valid
      end

      it 'rejects invalid colors' do
        measurement.color = 'red'
        expect(measurement).not_to be_valid
      end

      it 'rejects short hex colors' do
        measurement.color = '#FFF'
        expect(measurement).not_to be_valid
      end
    end

    describe 'line_width' do
      it 'accepts valid line widths' do
        measurement.line_width = 2.5
        expect(measurement).to be_valid
      end

      it 'rejects zero or negative widths' do
        measurement.line_width = 0
        expect(measurement).not_to be_valid
      end

      it 'rejects widths greater than 10' do
        measurement.line_width = 11
        expect(measurement).not_to be_valid
      end
    end

    describe 'points validation' do
      it 'requires points to be present' do
        measurement.points = nil
        expect(measurement).not_to be_valid
      end

      it 'validates points are arrays of 3D coordinates' do
        measurement.points = [[1, 2], [3, 4]]
        expect(measurement).not_to be_valid
        expect(measurement.errors[:points]).to include(/must be an array of 3 numeric values/)
      end

      it 'validates distance requires at least 2 points' do
        measurement.measurement_type = 'distance'
        measurement.points = [[0, 0, 0]]
        expect(measurement).not_to be_valid
        expect(measurement.errors[:points]).to include('distance requires at least 2 points')
      end

      it 'validates area requires at least 3 points' do
        measurement.measurement_type = 'area'
        measurement.unit = 'm²'
        measurement.points = [[0, 0, 0], [1, 0, 0]]
        expect(measurement).not_to be_valid
        expect(measurement.errors[:points]).to include('area requires at least 3 points')
      end

      it 'validates volume requires at least 2 points' do
        measurement.measurement_type = 'volume'
        measurement.unit = 'm³'
        measurement.points = [[0, 0, 0]]
        expect(measurement).not_to be_valid
      end

      it 'validates angle requires exactly 3 points' do
        measurement.measurement_type = 'angle'
        measurement.unit = 'degrees'
        measurement.points = [[0, 0, 0], [1, 0, 0]]
        expect(measurement).not_to be_valid
        expect(measurement.errors[:points]).to include('angle requires exactly 3 points')
      end

      it 'validates elevation requires at least 1 point' do
        measurement.measurement_type = 'elevation'
        measurement.points = []
        expect(measurement).not_to be_valid
      end
    end
  end

  describe 'scopes' do
    let!(:visible_measurement) { create(:bim_measurement, ifc_model: ifc_model, visible: true) }
    let!(:hidden_measurement) { create(:bim_measurement, ifc_model: ifc_model, visible: false) }
    let!(:distance_measurement) { create(:bim_measurement, :distance, ifc_model: ifc_model) }
    let!(:area_measurement) { create(:bim_measurement, :area, ifc_model: ifc_model) }

    describe '.visible' do
      it 'returns only visible measurements' do
        expect(described_class.visible).to include(visible_measurement)
        expect(described_class.visible).not_to include(hidden_measurement)
      end
    end

    describe '.hidden' do
      it 'returns only hidden measurements' do
        expect(described_class.hidden).to include(hidden_measurement)
        expect(described_class.hidden).not_to include(visible_measurement)
      end
    end

    describe '.for_model' do
      let(:other_model) { create(:ifc_model, project: project) }
      let!(:other_measurement) { create(:bim_measurement, ifc_model: other_model) }

      it 'returns measurements for specified model' do
        measurements = described_class.for_model(ifc_model.id)
        expect(measurements).to include(visible_measurement)
        expect(measurements).not_to include(other_measurement)
      end
    end

    describe '.distances' do
      it 'returns only distance measurements' do
        expect(described_class.distances).to include(distance_measurement)
        expect(described_class.distances).not_to include(area_measurement)
      end
    end

    describe '.areas' do
      it 'returns only area measurements' do
        expect(described_class.areas).to include(area_measurement)
        expect(described_class.areas).not_to include(distance_measurement)
      end
    end
  end

  describe '.calculate_distance' do
    it 'calculates distance between two points' do
      points = [[0, 0, 0], [3, 4, 0]]
      distance = described_class.calculate_distance(points)
      expect(distance).to eq(5.0)
    end

    it 'calculates multi-segment distance' do
      points = [[0, 0, 0], [3, 0, 0], [3, 4, 0]]
      distance = described_class.calculate_distance(points)
      expect(distance).to eq(7.0)
    end

    it 'calculates 3D distance' do
      points = [[0, 0, 0], [1, 1, 1]]
      distance = described_class.calculate_distance(points)
      expect(distance).to be_within(0.001).of(Math.sqrt(3))
    end

    it 'returns 0 for single point' do
      expect(described_class.calculate_distance([[0, 0, 0]])).to eq(0)
    end
  end

  describe '.calculate_area' do
    it 'calculates area of simple rectangle in XZ plane' do
      points = [[0, 0, 0], [10, 0, 0], [10, 0, 10], [0, 0, 10]]
      area = described_class.calculate_area(points)
      expect(area).to eq(100.0)
    end

    it 'calculates area of triangle' do
      points = [[0, 0, 0], [10, 0, 0], [5, 0, 10]]
      area = described_class.calculate_area(points)
      expect(area).to eq(50.0)
    end

    it 'returns 0 for less than 3 points' do
      expect(described_class.calculate_area([[0, 0, 0], [1, 0, 0]])).to eq(0)
    end
  end

  describe '.calculate_volume' do
    it 'calculates volume from bounding box' do
      points = [[0, 0, 0], [10, 5, 2]]
      volume = described_class.calculate_volume(points)
      expect(volume).to eq(100.0)
    end

    it 'handles negative coordinates' do
      points = [[-5, -5, -5], [5, 5, 5]]
      volume = described_class.calculate_volume(points)
      expect(volume).to eq(1000.0)
    end

    it 'returns 0 for single point' do
      expect(described_class.calculate_volume([[0, 0, 0]])).to eq(0)
    end
  end

  describe '.calculate_angle' do
    it 'calculates right angle (90 degrees)' do
      points = [[0, 0, 0], [1, 0, 0], [0, 1, 0]]
      angle = described_class.calculate_angle(points)
      expect(angle).to be_within(0.1).of(90.0)
    end

    it 'calculates 45 degree angle' do
      points = [[0, 0, 0], [1, 0, 0], [1, 1, 0]]
      angle = described_class.calculate_angle(points)
      expect(angle).to be_within(0.1).of(45.0)
    end

    it 'calculates 180 degree angle (straight line)' do
      points = [[0, 0, 0], [1, 0, 0], [-1, 0, 0]]
      angle = described_class.calculate_angle(points)
      expect(angle).to be_within(0.1).of(180.0)
    end

    it 'returns 0 for less than 3 points' do
      expect(described_class.calculate_angle([[0, 0, 0], [1, 0, 0]])).to eq(0)
    end
  end

  describe '.calculate_elevation' do
    it 'calculates elevation from ground level' do
      points = [[0, 10, 0]]
      elevation = described_class.calculate_elevation(points, 0)
      expect(elevation).to eq(10.0)
    end

    it 'calculates elevation from custom reference' do
      points = [[0, 15, 0]]
      elevation = described_class.calculate_elevation(points, 5)
      expect(elevation).to eq(10.0)
    end

    it 'returns 0 for empty points' do
      expect(described_class.calculate_elevation([])).to eq(0)
    end
  end

  describe '#formatted_value' do
    it 'formats distance measurements' do
      measurement.measurement_type = 'distance'
      measurement.value = 10.5678
      measurement.unit = 'm'
      expect(measurement.formatted_value).to eq('10.57 m')
    end

    it 'formats area measurements' do
      measurement.measurement_type = 'area'
      measurement.value = 25.3456
      measurement.unit = 'm²'
      expect(measurement.formatted_value).to eq('25.35 m²')
    end

    it 'formats angle measurements in degrees' do
      measurement.measurement_type = 'angle'
      measurement.value = 45.678
      measurement.unit = 'degrees'
      expect(measurement.formatted_value).to eq('45.7°')
    end
  end

  describe '#coordinates' do
    it 'returns points as array' do
      points = [[0, 0, 0], [10, 0, 0]]
      measurement.points = points
      expect(measurement.coordinates).to eq(points)
    end

    it 'returns empty array if points is nil' do
      measurement.points = nil
      expect(measurement.coordinates).to eq([])
    end
  end

  describe '#has_valid_points?' do
    it 'returns true for distance with 2+ points' do
      measurement.measurement_type = 'distance'
      measurement.points = [[0, 0, 0], [1, 1, 1]]
      expect(measurement.has_valid_points?).to be true
    end

    it 'returns false for distance with 1 point' do
      measurement.measurement_type = 'distance'
      measurement.points = [[0, 0, 0]]
      expect(measurement.has_valid_points?).to be false
    end

    it 'returns true for area with 3+ points' do
      measurement.measurement_type = 'area'
      measurement.points = [[0, 0, 0], [1, 0, 0], [0, 1, 0]]
      expect(measurement.has_valid_points?).to be true
    end

    it 'returns true for angle with exactly 3 points' do
      measurement.measurement_type = 'angle'
      measurement.points = [[0, 0, 0], [1, 0, 0], [0, 1, 0]]
      expect(measurement.has_valid_points?).to be true
    end
  end
end
