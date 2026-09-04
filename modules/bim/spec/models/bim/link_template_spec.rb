# frozen_string_literal: true

#-- copyright
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
#++

require 'rails_helper'

RSpec.describe Bim::LinkTemplate, type: :model do
  subject(:template) { build(:bim_link_template) }

  describe 'associations' do
    it { is_expected.to belong_to(:project).optional }
    it { is_expected.to belong_to(:author) }
    it { is_expected.to have_many(:element_links).dependent(:nullify) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:relationship_type) }
    it { is_expected.to validate_presence_of(:element_filters) }

    context 'with uniqueness' do
      let!(:existing_template) { create(:bim_link_template, name: 'Existing Template') }

      it 'validates uniqueness of name scoped to project' do
        duplicate = build(:bim_link_template,
                          name: 'Existing Template',
                          project: existing_template.project)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:name]).to include('has already been taken')
      end

      it 'allows same name in different projects' do
        different_project = create(:project)
        duplicate = build(:bim_link_template,
                          name: 'Existing Template',
                          project: different_project)
        expect(duplicate).to be_valid
      end
    end

    describe 'element_filters validation' do
      it 'is invalid with invalid filter keys' do
        template.element_filters = { 'invalid_key' => [] }
        expect(template).not_to be_valid
        expect(template.errors[:element_filters]).to be_present
      end

      it 'is invalid when types is not an array' do
        template.element_filters = { 'types' => 'IfcWall' }
        expect(template).not_to be_valid
      end

      it 'is invalid when locations is not a hash' do
        template.element_filters = { 'locations' => [] }
        expect(template).not_to be_valid
      end

      it 'is valid with proper structure' do
        template.element_filters = {
          'types' => ['IfcWall', 'IfcDoor'],
          'locations' => { 'storey' => ['Level 1', 'Level 2'] },
          'tags' => ['structural']
        }
        expect(template).to be_valid
      end
    end

    describe 'project consistency validation' do
      it 'is invalid when public and has project' do
        template.public = true
        template.project = create(:project)
        expect(template).not_to be_valid
        expect(template.errors[:base]).to include('Public templates cannot be project-specific')
      end

      it 'is valid when public and no project' do
        template.public = true
        template.project = nil
        expect(template).to be_valid
      end
    end
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:relationship_type).with_values(affected_by: 0, responsible_for: 1, depends_on: 2, observes: 3, related_to: 4) }
  end

  describe 'scopes' do
    let!(:public_template) { create(:bim_link_template, :public_template) }
    let!(:private_template) { create(:bim_link_template) }
    let!(:auto_template) { create(:bim_link_template, :auto_apply) }
    let!(:affected_template) { create(:bim_link_template, :affected_by) }

    describe '.public_templates' do
      it 'returns only public templates' do
        expect(described_class.public_templates).to contain_exactly(public_template)
      end
    end

    describe '.private_templates' do
      it 'returns only private templates' do
        expect(described_class.private_templates).to include(private_template, auto_template, affected_template)
      end
    end

    describe '.auto_apply_templates' do
      it 'returns only auto-apply templates' do
        expect(described_class.auto_apply_templates).to contain_exactly(auto_template)
      end
    end

    describe '.by_relationship' do
      it 'returns templates with specified relationship type' do
        expect(described_class.by_relationship(:affected_by)).to contain_exactly(affected_template)
      end
    end
  end

  describe '#element_matches_filters?' do
    let(:element_data) do
      {
        'properties' => {
          'type' => 'IfcWall',
          'name' => 'Wall-001',
          'tags' => ['structural', 'external'],
          'classifications' => [
            { 'system' => 'Uniclass', 'code' => 'Ss_25_10_20' }
          ],
          'LoadBearing' => 'True'
        },
        'spatial_structure' => {
          'building' => 'Building A',
          'storey' => 'Level 1',
          'space' => 'Room 101'
        }
      }
    end

    context 'with type filter' do
      before do
        template.element_filters = { 'types' => ['IfcWall', 'IfcColumn'] }
      end

      it 'matches when element type is in list' do
        expect(template.element_matches_filters?(element_data)).to be true
      end

      it 'does not match when element type is not in list' do
        element_data['properties']['type'] = 'IfcDoor'
        expect(template.element_matches_filters?(element_data)).to be false
      end
    end

    context 'with location filter' do
      before do
        template.element_filters = {
          'locations' => {
            'storey' => ['Level 1', 'Level 2']
          }
        }
      end

      it 'matches when element location matches' do
        expect(template.element_matches_filters?(element_data)).to be true
      end

      it 'does not match when element location does not match' do
        element_data['spatial_structure']['storey'] = 'Level 3'
        expect(template.element_matches_filters?(element_data)).to be false
      end
    end

    context 'with classification filter' do
      before do
        template.element_filters = {
          'classifications' => [
            { 'system' => 'Uniclass', 'code' => 'Ss_25_10_20' }
          ]
        }
      end

      it 'matches when element has matching classification' do
        expect(template.element_matches_filters?(element_data)).to be true
      end

      it 'does not match when classification is different' do
        element_data['properties']['classifications'] = [
          { 'system' => 'Uniclass', 'code' => 'Different' }
        ]
        expect(template.element_matches_filters?(element_data)).to be false
      end
    end

    context 'with property filter' do
      before do
        template.element_filters = {
          'properties' => {
            'LoadBearing' => 'True'
          }
        }
      end

      it 'matches when property value equals' do
        expect(template.element_matches_filters?(element_data)).to be true
      end

      it 'does not match when property value differs' do
        element_data['properties']['LoadBearing'] = 'False'
        expect(template.element_matches_filters?(element_data)).to be false
      end
    end

    context 'with property operators' do
      before do
        element_data['properties']['Height'] = '3.5'
      end

      it 'matches gt operator' do
        template.element_filters = { 'properties' => { 'Height' => { 'gt' => 3.0 } } }
        expect(template.element_matches_filters?(element_data)).to be true
      end

      it 'matches gte operator' do
        template.element_filters = { 'properties' => { 'Height' => { 'gte' => 3.5 } } }
        expect(template.element_matches_filters?(element_data)).to be true
      end

      it 'matches lt operator' do
        template.element_filters = { 'properties' => { 'Height' => { 'lt' => 4.0 } } }
        expect(template.element_matches_filters?(element_data)).to be true
      end

      it 'matches contains operator' do
        template.element_filters = { 'properties' => { 'name' => { 'contains' => 'Wall' } } }
        expect(template.element_matches_filters?(element_data)).to be true
      end
    end

    context 'with tags filter' do
      before do
        template.element_filters = { 'tags' => ['structural'] }
      end

      it 'matches when element has one of the tags' do
        expect(template.element_matches_filters?(element_data)).to be true
      end

      it 'does not match when element has no matching tags' do
        element_data['properties']['tags'] = ['interior', 'non-structural']
        expect(template.element_matches_filters?(element_data)).to be false
      end
    end
  end

  describe '#find_matching_elements' do
    let(:ifc_model) { create(:ifc_model, :with_xkt_attachment) }

    before do
      # Mock metadata with test elements
      allow(ifc_model).to receive(:metadata).and_return({
                                                           'elements' => {
                                                             'wall-1' => {
                                                               'properties' => { 'type' => 'IfcWall' },
                                                               'spatial_structure' => { 'storey' => 'Level 1' }
                                                             },
                                                             'wall-2' => {
                                                               'properties' => { 'type' => 'IfcWall' },
                                                               'spatial_structure' => { 'storey' => 'Level 2' }
                                                             },
                                                             'door-1' => {
                                                               'properties' => { 'type' => 'IfcDoor' },
                                                               'spatial_structure' => { 'storey' => 'Level 1' }
                                                             }
                                                           }
                                                         })
    end

    it 'returns all matching element IDs' do
      template.element_filters = { 'types' => ['IfcWall'] }
      result = template.find_matching_elements(ifc_model)
      expect(result).to contain_exactly('wall-1', 'wall-2')
    end

    it 'returns elements matching multiple filters' do
      template.element_filters = {
        'types' => ['IfcWall'],
        'locations' => { 'storey' => ['Level 1'] }
      }
      result = template.find_matching_elements(ifc_model)
      expect(result).to contain_exactly('wall-1')
    end

    it 'returns empty array when no elements match' do
      template.element_filters = { 'types' => ['IfcColumn'] }
      result = template.find_matching_elements(ifc_model)
      expect(result).to be_empty
    end
  end

  describe '#apply_to' do
    let(:work_package) { create(:work_package) }
    let(:ifc_model) { create(:ifc_model, :with_xkt_attachment) }

    before do
      allow(ifc_model).to receive(:metadata).and_return({
                                                           'elements' => {
                                                             'wall-1' => { 'properties' => { 'type' => 'IfcWall' } },
                                                             'wall-2' => { 'properties' => { 'type' => 'IfcWall' } }
                                                           }
                                                         })
      template.element_filters = { 'types' => ['IfcWall'] }
    end

    it 'creates links for matching elements' do
      expect do
        template.apply_to(work_package: work_package, ifc_model: ifc_model)
      end.to change(Bim::ElementLink, :count).by(2)
    end

    it 'returns created links' do
      links = template.apply_to(work_package: work_package, ifc_model: ifc_model)
      expect(links).to all(be_a(Bim::ElementLink))
      expect(links.map(&:element_id)).to contain_exactly('wall-1', 'wall-2')
    end

    it 'does not create links in dry_run mode' do
      expect do
        template.apply_to(work_package: work_package, ifc_model: ifc_model, dry_run: true)
      end.not_to change(Bim::ElementLink, :count)
    end

    it 'returns element IDs in dry_run mode' do
      result = template.apply_to(work_package: work_package, ifc_model: ifc_model, dry_run: true)
      expect(result).to contain_exactly('wall-1', 'wall-2')
    end
  end

  describe '#statistics' do
    let(:template) { create(:bim_link_template) }
    let!(:link1) { create(:bim_element_link, template: template, status: :active) }
    let!(:link2) { create(:bim_element_link, template: template, status: :completed) }
    let!(:link3) { create(:bim_element_link, template: template, status: :archived) }

    it 'returns correct statistics' do
      stats = template.statistics
      expect(stats[:total_links]).to eq(3)
      expect(stats[:active_links]).to eq(1)
      expect(stats[:completed_links]).to eq(1)
      expect(stats[:archived_links]).to eq(1)
    end
  end

  describe '#clone_template' do
    let(:template) { create(:bim_link_template, name: 'Original') }

    it 'creates a new template with same attributes' do
      cloned = template.clone_template(new_name: 'Cloned')
      expect(cloned).to be_a(described_class)
      expect(cloned.name).to eq('Cloned')
      expect(cloned.relationship_type).to eq(template.relationship_type)
      expect(cloned.element_filters).to eq(template.element_filters)
    end

    it 'sets cloned template as private' do
      cloned = template.clone_template(new_name: 'Cloned')
      expect(cloned.public).to be false
    end

    it 'applies modifications' do
      cloned = template.clone_template(
        new_name: 'Cloned',
        modifications: { description: 'Modified description' }
      )
      expect(cloned.description).to eq('Modified description')
    end
  end
end
