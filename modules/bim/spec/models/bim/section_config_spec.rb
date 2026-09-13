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

RSpec.describe Bim::SectionConfig, type: :model do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:ifc_model) { create(:ifc_model, project: project) }

  subject(:section_config) do
    described_class.new(
      ifc_model: ifc_model,
      user: user,
      name: 'Test Section',
      section_boxes: [],
      section_planes: []
    )
  end

  describe 'associations' do
    it { is_expected.to belong_to(:ifc_model) }
    it { is_expected.to belong_to(:user).optional }
  end

  describe 'validations' do
    context 'with valid attributes' do
      it 'is valid' do
        expect(section_config).to be_valid
      end
    end

    describe 'name' do
      it 'requires name to be present' do
        section_config.name = nil
        expect(section_config).not_to be_valid
      end

      it 'requires name to be unique per model' do
        create(:bim_section_config, ifc_model: ifc_model, name: 'Unique')
        duplicate = build(:bim_section_config, ifc_model: ifc_model, name: 'Unique')
        expect(duplicate).not_to be_valid
      end

      it 'allows same name for different models' do
        other_model = create(:ifc_model, project: project)
        create(:bim_section_config, ifc_model: ifc_model, name: 'Same')
        other_config = build(:bim_section_config, ifc_model: other_model, name: 'Same')
        expect(other_config).to be_valid
      end
    end

    describe 'edge_color' do
      it 'accepts valid hex colors' do
        section_config.edge_color = '#FF0000'
        expect(section_config).to be_valid
      end

      it 'rejects invalid hex colors' do
        section_config.edge_color = 'red'
        expect(section_config).not_to be_valid
      end

      it 'rejects short hex colors' do
        section_config.edge_color = '#FFF'
        expect(section_config).not_to be_valid
      end
    end

    describe 'fill_color' do
      it 'accepts valid hex colors' do
        section_config.fill_color = '#00FF00'
        expect(section_config).to be_valid
      end

      it 'rejects invalid colors' do
        section_config.fill_color = 'green'
        expect(section_config).not_to be_valid
      end
    end

    describe 'fill_opacity' do
      it 'accepts values between 0 and 1' do
        section_config.fill_opacity = 0.5
        expect(section_config).to be_valid
      end

      it 'rejects negative values' do
        section_config.fill_opacity = -0.1
        expect(section_config).not_to be_valid
      end

      it 'rejects values greater than 1' do
        section_config.fill_opacity = 1.1
        expect(section_config).not_to be_valid
      end
    end

    describe 'section_boxes validation' do
      it 'accepts valid section box' do
        section_config.section_boxes = [
          { 'min' => [0.0, 0.0, 0.0], 'max' => [10.0, 10.0, 10.0], 'enabled' => true }
        ]
        expect(section_config).to be_valid
      end

      it 'rejects box with invalid min vector' do
        section_config.section_boxes = [
          { 'min' => [0.0, 0.0], 'max' => [10.0, 10.0, 10.0] }
        ]
        expect(section_config).not_to be_valid
        expect(section_config.errors[:section_boxes]).to include(/min.*3 numeric values/)
      end

      it 'rejects box with invalid max vector' do
        section_config.section_boxes = [
          { 'min' => [0.0, 0.0, 0.0], 'max' => ['a', 'b', 'c'] }
        ]
        expect(section_config).not_to be_valid
      end

      it 'rejects box where max <= min' do
        section_config.section_boxes = [
          { 'min' => [10.0, 10.0, 10.0], 'max' => [5.0, 15.0, 15.0] }
        ]
        expect(section_config).not_to be_valid
        expect(section_config.errors[:section_boxes]).to include(/max\[0\] must be greater than min/)
      end

      it 'accepts multiple valid boxes' do
        section_config.section_boxes = [
          { 'min' => [0.0, 0.0, 0.0], 'max' => [10.0, 10.0, 10.0], 'enabled' => true },
          { 'min' => [-5.0, -5.0, -5.0], 'max' => [5.0, 5.0, 5.0], 'enabled' => false }
        ]
        expect(section_config).to be_valid
      end
    end

    describe 'section_planes validation' do
      it 'accepts valid section plane' do
        section_config.section_planes = [
          { 'pos' => [0.0, 0.0, 0.0], 'dir' => [0.0, 1.0, 0.0], 'enabled' => true }
        ]
        expect(section_config).to be_valid
      end

      it 'rejects plane with invalid position vector' do
        section_config.section_planes = [
          { 'pos' => [0.0, 0.0], 'dir' => [0.0, 1.0, 0.0] }
        ]
        expect(section_config).not_to be_valid
      end

      it 'rejects plane with invalid direction vector' do
        section_config.section_planes = [
          { 'pos' => [0.0, 0.0, 0.0], 'dir' => [1.0, 2.0] }
        ]
        expect(section_config).not_to be_valid
      end

      it 'rejects plane with zero direction vector' do
        section_config.section_planes = [
          { 'pos' => [0.0, 0.0, 0.0], 'dir' => [0.0, 0.0, 0.0] }
        ]
        expect(section_config).not_to be_valid
        expect(section_config.errors[:section_planes]).to include(/non-zero vector/)
      end
    end
  end

  describe 'scopes' do
    let!(:public_config) { create(:bim_section_config, ifc_model: ifc_model, is_public: true) }
    let!(:private_config) { create(:bim_section_config, ifc_model: ifc_model, is_public: false) }

    describe '.public_configs' do
      it 'returns only public configs' do
        expect(described_class.public_configs).to include(public_config)
        expect(described_class.public_configs).not_to include(private_config)
      end
    end

    describe '.private_configs' do
      it 'returns only private configs' do
        expect(described_class.private_configs).to include(private_config)
        expect(described_class.private_configs).not_to include(public_config)
      end
    end
  end

  describe '#add_section_box' do
    it 'adds a section box to the configuration' do
      section_config.add_section_box(
        min: [0.0, 0.0, 0.0],
        max: [10.0, 10.0, 10.0],
        enabled: true
      )

      expect(section_config.section_boxes.length).to eq(1)
      expect(section_config.section_boxes.first['min']).to eq([0.0, 0.0, 0.0])
      expect(section_config.section_boxes.first['max']).to eq([10.0, 10.0, 10.0])
      expect(section_config.section_boxes.first['enabled']).to eq(true)
    end

    it 'adds multiple boxes' do
      section_config.add_section_box(min: [0.0, 0.0, 0.0], max: [5.0, 5.0, 5.0])
      section_config.add_section_box(min: [-10.0, -10.0, -10.0], max: [0.0, 0.0, 0.0])

      expect(section_config.section_boxes.length).to eq(2)
    end
  end

  describe '#remove_section_box' do
    before do
      section_config.section_boxes = [
        { 'min' => [0.0, 0.0, 0.0], 'max' => [5.0, 5.0, 5.0] },
        { 'min' => [10.0, 10.0, 10.0], 'max' => [15.0, 15.0, 15.0] }
      ]
    end

    it 'removes box at specified index' do
      section_config.remove_section_box(0)
      expect(section_config.section_boxes.length).to eq(1)
      expect(section_config.section_boxes.first['min']).to eq([10.0, 10.0, 10.0])
    end
  end

  describe '#enabled_section_boxes' do
    before do
      section_config.section_boxes = [
        { 'min' => [0.0, 0.0, 0.0], 'max' => [5.0, 5.0, 5.0], 'enabled' => true },
        { 'min' => [10.0, 10.0, 10.0], 'max' => [15.0, 15.0, 15.0], 'enabled' => false },
        { 'min' => [20.0, 20.0, 20.0], 'max' => [25.0, 25.0, 25.0], 'enabled' => true }
      ]
    end

    it 'returns only enabled boxes' do
      enabled = section_config.enabled_section_boxes
      expect(enabled.length).to eq(2)
      expect(enabled.all? { |box| box['enabled'] }).to be true
    end
  end

  describe '#add_section_plane' do
    it 'adds a section plane to the configuration' do
      section_config.add_section_plane(
        pos: [0.0, 0.0, 0.0],
        dir: [0.0, 1.0, 0.0],
        enabled: true
      )

      expect(section_config.section_planes.length).to eq(1)
      expect(section_config.section_planes.first['pos']).to eq([0.0, 0.0, 0.0])
      expect(section_config.section_planes.first['dir']).to eq([0.0, 1.0, 0.0])
    end
  end

  describe '#remove_section_plane' do
    before do
      section_config.section_planes = [
        { 'pos' => [0.0, 0.0, 0.0], 'dir' => [0.0, 1.0, 0.0] },
        { 'pos' => [10.0, 0.0, 0.0], 'dir' => [1.0, 0.0, 0.0] }
      ]
    end

    it 'removes plane at specified index' do
      section_config.remove_section_plane(0)
      expect(section_config.section_planes.length).to eq(1)
    end
  end

  describe '#enabled_section_planes' do
    before do
      section_config.section_planes = [
        { 'pos' => [0.0, 0.0, 0.0], 'dir' => [0.0, 1.0, 0.0], 'enabled' => true },
        { 'pos' => [10.0, 0.0, 0.0], 'dir' => [1.0, 0.0, 0.0], 'enabled' => false }
      ]
    end

    it 'returns only enabled planes' do
      enabled = section_config.enabled_section_planes
      expect(enabled.length).to eq(1)
    end
  end

  describe '#configuration_summary' do
    before do
      section_config.section_boxes = [
        { 'min' => [0.0, 0.0, 0.0], 'max' => [5.0, 5.0, 5.0], 'enabled' => true },
        { 'min' => [10.0, 10.0, 10.0], 'max' => [15.0, 15.0, 15.0], 'enabled' => false }
      ]
      section_config.section_planes = [
        { 'pos' => [0.0, 0.0, 0.0], 'dir' => [0.0, 1.0, 0.0], 'enabled' => true }
      ]
      section_config.show_edges = true
      section_config.show_fills = false
    end

    it 'returns configuration summary' do
      summary = section_config.configuration_summary

      expect(summary[:boxes_count]).to eq(2)
      expect(summary[:planes_count]).to eq(1)
      expect(summary[:enabled_boxes]).to eq(1)
      expect(summary[:enabled_planes]).to eq(1)
      expect(summary[:show_edges]).to be true
      expect(summary[:show_fills]).to be false
    end
  end
end
