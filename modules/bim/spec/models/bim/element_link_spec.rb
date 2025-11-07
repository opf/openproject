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

RSpec.describe Bim::ElementLink, type: :model do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:work_package) { create(:work_package, project: project) }
  let(:ifc_model) { create(:ifc_model, project: project) }
  let(:element_id) { '2O2Fr$t4X7Zf8NOew3FNr2' }

  subject(:element_link) do
    described_class.new(
      work_package: work_package,
      ifc_model: ifc_model,
      user: user,
      element_id: element_id,
      element_type: 'IfcWall',
      element_name: 'Wall-001',
      relationship_type: :affected_by,
      status: :active
    )
  end

  describe 'associations' do
    it { is_expected.to belong_to(:work_package) }
    it { is_expected.to belong_to(:ifc_model) }
    it { is_expected.to belong_to(:user).optional }
  end

  describe 'validations' do
    context 'with valid attributes' do
      it 'is valid' do
        expect(element_link).to be_valid
      end
    end

    describe 'element_id' do
      it 'requires element_id to be present' do
        element_link.element_id = nil
        expect(element_link).not_to be_valid
        expect(element_link.errors[:element_id]).to include("can't be blank")
      end

      it 'limits element_id to 50 characters' do
        element_link.element_id = 'a' * 51
        expect(element_link).not_to be_valid
      end

      it 'requires element_id to be unique per work package' do
        create(:bim_element_link, work_package: work_package, element_id: element_id)
        duplicate = build(:bim_element_link, work_package: work_package, element_id: element_id)

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:element_id]).to include('has already been taken')
      end

      it 'allows same element_id for different work packages' do
        other_wp = create(:work_package, project: project)
        create(:bim_element_link, work_package: work_package, element_id: element_id)
        other_link = build(:bim_element_link, work_package: other_wp, element_id: element_id)

        expect(other_link).to be_valid
      end
    end

    describe 'relationship_type' do
      it 'requires relationship_type to be present' do
        element_link.relationship_type = nil
        expect(element_link).not_to be_valid
      end

      it 'accepts valid relationship types' do
        %i[affected_by responsible_for depends_on observes related_to].each do |type|
          element_link.relationship_type = type
          expect(element_link).to be_valid
        end
      end
    end

    describe 'status' do
      it 'requires status to be present' do
        element_link.status = nil
        expect(element_link).not_to be_valid
      end

      it 'accepts valid statuses' do
        %i[active completed archived].each do |status|
          element_link.status = status
          expect(element_link).to be_valid
        end
      end
    end
  end

  describe 'enums' do
    describe 'relationship_type' do
      it 'defines relationship types' do
        expect(described_class.relationship_types).to eq({
          'affected_by' => 0,
          'responsible_for' => 1,
          'depends_on' => 2,
          'observes' => 3,
          'related_to' => 4
        })
      end
    end

    describe 'status' do
      it 'defines statuses' do
        expect(described_class.statuses).to eq({
          'active' => 0,
          'completed' => 1,
          'archived' => 2
        })
      end
    end
  end

  describe 'scopes' do
    let!(:active_link) { create(:bim_element_link, status: :active) }
    let!(:completed_link) { create(:bim_element_link, status: :completed) }
    let!(:archived_link) { create(:bim_element_link, status: :archived) }
    let!(:wall_link) { create(:bim_element_link, element_type: 'IfcWall') }
    let!(:door_link) { create(:bim_element_link, element_type: 'IfcDoor') }

    describe '.active' do
      it 'returns only active links' do
        expect(described_class.active).to include(active_link)
        expect(described_class.active).not_to include(completed_link, archived_link)
      end
    end

    describe '.completed' do
      it 'returns only completed links' do
        expect(described_class.completed).to include(completed_link)
        expect(described_class.completed).not_to include(active_link, archived_link)
      end
    end

    describe '.archived' do
      it 'returns only archived links' do
        expect(described_class.archived).to include(archived_link)
        expect(described_class.archived).not_to include(active_link, completed_link)
      end
    end

    describe '.by_element_type' do
      it 'returns links for specified element type' do
        links = described_class.by_element_type('IfcWall')
        expect(links).to include(wall_link)
        expect(links).not_to include(door_link)
      end
    end

    describe '.by_relationship' do
      let!(:affected_link) { create(:bim_element_link, relationship_type: :affected_by) }
      let!(:responsible_link) { create(:bim_element_link, relationship_type: :responsible_for) }

      it 'returns links for specified relationship type' do
        links = described_class.by_relationship(:affected_by)
        expect(links).to include(affected_link)
        expect(links).not_to include(responsible_link)
      end
    end
  end

  describe '#element_metadata' do
    let(:metadata) do
      {
        'id' => element_id,
        'type' => 'IfcWall',
        'name' => 'Wall-001',
        'properties' => { 'LoadBearing' => true },
        'geometry' => { 'hash' => 'abc123' }
      }
    end

    before do
      ifc_metadata = double('IFCModelMetadata')
      allow(ifc_model).to receive(:ifc_model_metadata).and_return(ifc_metadata)
      allow(ifc_metadata).to receive(:find_element).with(element_id).and_return(metadata)
    end

    it 'retrieves element metadata from IFC model' do
      expect(element_link.element_metadata).to eq(metadata)
    end

    it 'caches the metadata' do
      expect(ifc_model.ifc_model_metadata).to receive(:find_element).once.and_return(metadata)
      element_link.element_metadata
      element_link.element_metadata
    end
  end

  describe '#geometry_changed?' do
    let(:stored_properties) do
      { 'geometry' => { 'hash' => 'abc123' } }
    end

    before do
      element_link.element_properties = stored_properties
    end

    context 'when geometry has not changed' do
      let(:current_metadata) do
        { 'geometry' => { 'hash' => 'abc123' } }
      end

      before do
        allow(element_link).to receive(:element_metadata).and_return(current_metadata)
      end

      it 'returns false' do
        expect(element_link.geometry_changed?).to be false
      end
    end

    context 'when geometry has changed' do
      let(:current_metadata) do
        { 'geometry' => { 'hash' => 'xyz789' } }
      end

      before do
        allow(element_link).to receive(:element_metadata).and_return(current_metadata)
      end

      it 'returns true' do
        expect(element_link.geometry_changed?).to be true
      end
    end

    context 'when metadata is unavailable' do
      before do
        allow(element_link).to receive(:element_metadata).and_return(nil)
      end

      it 'returns false' do
        expect(element_link.geometry_changed?).to be false
      end
    end
  end

  describe '#properties_changed?' do
    let(:stored_properties) do
      { 'properties' => { 'LoadBearing' => true } }
    end

    before do
      element_link.element_properties = stored_properties
    end

    context 'when properties have not changed' do
      let(:current_metadata) do
        { 'properties' => { 'LoadBearing' => true } }
      end

      before do
        allow(element_link).to receive(:element_metadata).and_return(current_metadata)
      end

      it 'returns false' do
        expect(element_link.properties_changed?).to be false
      end
    end

    context 'when properties have changed' do
      let(:current_metadata) do
        { 'properties' => { 'LoadBearing' => false } }
      end

      before do
        allow(element_link).to receive(:element_metadata).and_return(current_metadata)
      end

      it 'returns true' do
        expect(element_link.properties_changed?).to be true
      end
    end
  end

  describe '#display_name' do
    it 'returns element_name if present' do
      element_link.element_name = 'Wall-001'
      expect(element_link.display_name).to eq('Wall-001')
    end

    it 'falls back to metadata name if element_name is blank' do
      element_link.element_name = nil
      allow(element_link).to receive(:element_metadata).and_return({ 'name' => 'Wall from metadata' })
      expect(element_link.display_name).to eq('Wall from metadata')
    end

    it 'falls back to element_id if both are blank' do
      element_link.element_name = nil
      allow(element_link).to receive(:element_metadata).and_return({})
      expect(element_link.display_name).to eq(element_id)
    end
  end

  describe '#display_type' do
    it 'returns element_type if present' do
      element_link.element_type = 'IfcWall'
      expect(element_link.display_type).to eq('IfcWall')
    end

    it 'falls back to metadata type if element_type is blank' do
      element_link.element_type = nil
      allow(element_link).to receive(:element_metadata).and_return({ 'type' => 'IfcDoor' })
      expect(element_link.display_type).to eq('IfcDoor')
    end

    it 'returns Unknown if both are blank' do
      element_link.element_type = nil
      allow(element_link).to receive(:element_metadata).and_return({})
      expect(element_link.display_type).to eq('Unknown')
    end
  end

  describe '#element_location' do
    let(:metadata) do
      {
        'spatial_structure' => {
          'building' => 'Main Building',
          'storey' => 'Level 1',
          'space' => 'Room 101'
        }
      }
    end

    before do
      allow(element_link).to receive(:element_metadata).and_return(metadata)
    end

    it 'returns spatial location from metadata' do
      location = element_link.element_location
      expect(location[:building]).to eq('Main Building')
      expect(location[:storey]).to eq('Level 1')
      expect(location[:space]).to eq('Room 101')
    end

    it 'returns nil if metadata is unavailable' do
      allow(element_link).to receive(:element_metadata).and_return(nil)
      expect(element_link.element_location).to be_nil
    end
  end

  describe '#changes_summary' do
    before do
      element_link.element_properties = { 'geometry' => { 'hash' => 'abc' }, 'properties' => {} }
    end

    it 'returns nil when nothing has changed' do
      allow(element_link).to receive(:geometry_changed?).and_return(false)
      allow(element_link).to receive(:properties_changed?).and_return(false)
      expect(element_link.changes_summary).to be_nil
    end

    it 'includes geometry change' do
      allow(element_link).to receive(:geometry_changed?).and_return(true)
      allow(element_link).to receive(:properties_changed?).and_return(false)
      expect(element_link.changes_summary).to include('Geometry modified')
    end

    it 'includes properties change' do
      allow(element_link).to receive(:geometry_changed?).and_return(false)
      allow(element_link).to receive(:properties_changed?).and_return(true)
      expect(element_link.changes_summary).to include('Properties modified')
    end

    it 'includes both changes' do
      allow(element_link).to receive(:geometry_changed?).and_return(true)
      allow(element_link).to receive(:properties_changed?).and_return(true)
      summary = element_link.changes_summary
      expect(summary).to include('Geometry modified')
      expect(summary).to include('Properties modified')
    end
  end

  describe '#complete!' do
    it 'marks link as completed' do
      element_link.save!
      element_link.complete!
      expect(element_link.reload.status).to eq('completed')
    end
  end

  describe '#archive!' do
    it 'marks link as archived' do
      element_link.save!
      element_link.archive!
      expect(element_link.reload.status).to eq('archived')
    end
  end

  describe '#reactivate!' do
    it 'reactivates archived link' do
      element_link.status = :archived
      element_link.save!
      element_link.reactivate!
      expect(element_link.reload.status).to eq('active')
    end
  end
end
