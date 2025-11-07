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

RSpec.describe Bim::SavedView, type: :model do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:ifc_model) { create(:ifc_model, project: project) }

  let(:valid_camera_eye) { [10.0, 20.0, 30.0] }
  let(:valid_camera_look) { [0.0, 0.0, 0.0] }
  let(:valid_camera_up) { [0.0, 1.0, 0.0] }

  subject(:saved_view) do
    described_class.new(
      ifc_model: ifc_model,
      user: user,
      name: 'Test View',
      camera_eye: valid_camera_eye,
      camera_look: valid_camera_look,
      camera_up: valid_camera_up,
      projection: 'perspective'
    )
  end

  describe 'associations' do
    it { is_expected.to belong_to(:ifc_model) }
    it { is_expected.to belong_to(:user).optional }
  end

  describe 'validations' do
    context 'with valid attributes' do
      it 'is valid' do
        expect(saved_view).to be_valid
      end
    end

    describe 'name' do
      it 'requires name to be present' do
        saved_view.name = nil
        expect(saved_view).not_to be_valid
        expect(saved_view.errors[:name]).to include("can't be blank")
      end

      it 'requires name to be unique per model' do
        create(:bim_saved_view, ifc_model: ifc_model, name: 'Unique View')
        duplicate = build(:bim_saved_view, ifc_model: ifc_model, name: 'Unique View')

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:name]).to include('has already been taken')
      end

      it 'allows same name for different models' do
        other_model = create(:ifc_model, project: project)
        create(:bim_saved_view, ifc_model: ifc_model, name: 'Same Name')
        other_view = build(:bim_saved_view, ifc_model: other_model, name: 'Same Name')

        expect(other_view).to be_valid
      end

      it 'limits name to 255 characters' do
        saved_view.name = 'a' * 256
        expect(saved_view).not_to be_valid
      end
    end

    describe 'camera vectors' do
      it 'requires camera_eye to be present' do
        saved_view.camera_eye = nil
        expect(saved_view).not_to be_valid
        expect(saved_view.errors[:camera_eye]).to include("can't be blank")
      end

      it 'requires camera_look to be present' do
        saved_view.camera_look = nil
        expect(saved_view).not_to be_valid
      end

      it 'requires camera_up to be present' do
        saved_view.camera_up = nil
        expect(saved_view).not_to be_valid
      end

      it 'validates camera_eye is an array of 3 numbers' do
        saved_view.camera_eye = [1.0, 2.0]
        expect(saved_view).not_to be_valid
        expect(saved_view.errors[:camera_eye]).to include('Camera eye must be an array of 3 numeric values')
      end

      it 'validates camera_look is an array of 3 numbers' do
        saved_view.camera_look = ['a', 'b', 'c']
        expect(saved_view).not_to be_valid
      end

      it 'validates camera_up is an array of 3 numbers' do
        saved_view.camera_up = [1.0, 2.0, 3.0, 4.0]
        expect(saved_view).not_to be_valid
      end
    end

    describe 'projection' do
      it 'accepts perspective projection' do
        saved_view.projection = 'perspective'
        expect(saved_view).to be_valid
      end

      it 'accepts orthogonal projection' do
        saved_view.projection = 'orthogonal'
        expect(saved_view).to be_valid
      end

      it 'rejects invalid projection types' do
        saved_view.projection = 'invalid'
        expect(saved_view).not_to be_valid
      end
    end
  end

  describe 'scopes' do
    let!(:public_view) { create(:bim_saved_view, ifc_model: ifc_model, is_public: true) }
    let!(:private_view) { create(:bim_saved_view, ifc_model: ifc_model, is_public: false) }

    describe '.public_views' do
      it 'returns only public views' do
        expect(described_class.public_views).to include(public_view)
        expect(described_class.public_views).not_to include(private_view)
      end
    end

    describe '.private_views' do
      it 'returns only private views' do
        expect(described_class.private_views).to include(private_view)
        expect(described_class.private_views).not_to include(public_view)
      end
    end

    describe '.for_model' do
      let(:other_model) { create(:ifc_model, project: project) }
      let!(:other_view) { create(:bim_saved_view, ifc_model: other_model) }

      it 'returns views for specified model' do
        views = described_class.for_model(ifc_model.id)
        expect(views).to include(public_view, private_view)
        expect(views).not_to include(other_view)
      end
    end

    describe '.for_user' do
      let(:user1) { create(:user) }
      let(:user2) { create(:user) }
      let!(:user1_view) { create(:bim_saved_view, ifc_model: ifc_model, user: user1) }
      let!(:user2_view) { create(:bim_saved_view, ifc_model: ifc_model, user: user2) }

      it 'returns views for specified user' do
        views = described_class.for_user(user1.id)
        expect(views).to include(user1_view)
        expect(views).not_to include(user2_view)
      end
    end
  end

  describe '#camera_position' do
    it 'returns camera configuration as hash' do
      position = saved_view.camera_position

      expect(position[:eye]).to eq(valid_camera_eye)
      expect(position[:look]).to eq(valid_camera_look)
      expect(position[:up]).to eq(valid_camera_up)
      expect(position[:projection]).to eq('perspective')
    end
  end

  describe '#camera_position=' do
    it 'sets all camera attributes from hash with symbol keys' do
      new_position = {
        eye: [5.0, 10.0, 15.0],
        look: [1.0, 1.0, 1.0],
        up: [0.0, 0.0, 1.0],
        projection: 'orthogonal'
      }

      saved_view.camera_position = new_position

      expect(saved_view.camera_eye).to eq([5.0, 10.0, 15.0])
      expect(saved_view.camera_look).to eq([1.0, 1.0, 1.0])
      expect(saved_view.camera_up).to eq([0.0, 0.0, 1.0])
      expect(saved_view.projection).to eq('orthogonal')
    end

    it 'sets all camera attributes from hash with string keys' do
      new_position = {
        'eye' => [5.0, 10.0, 15.0],
        'look' => [1.0, 1.0, 1.0],
        'up' => [0.0, 0.0, 1.0],
        'projection' => 'orthogonal'
      }

      saved_view.camera_position = new_position

      expect(saved_view.camera_eye).to eq([5.0, 10.0, 15.0])
    end

    it 'defaults projection to perspective if not provided' do
      saved_view.camera_position = {
        eye: [5.0, 10.0, 15.0],
        look: [1.0, 1.0, 1.0],
        up: [0.0, 0.0, 1.0]
      }

      expect(saved_view.projection).to eq('perspective')
    end
  end
end
