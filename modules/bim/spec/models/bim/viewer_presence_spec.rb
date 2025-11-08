# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bim::ViewerPresence, type: :model do
  let(:ifc_model) { create(:bim_ifc_model) }
  let(:user) { create(:user) }
  let(:presence) { create(:bim_viewer_presence, ifc_model: ifc_model, user: user) }

  describe 'associations' do
    it { is_expected.to belong_to(:ifc_model) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    subject { build(:bim_viewer_presence) }

    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:ifc_model) }
    it { is_expected.to validate_presence_of(:last_seen_at) }

    it 'validates uniqueness of ifc_model_id scoped to user_id' do
      existing = create(:bim_viewer_presence)
      duplicate = build(:bim_viewer_presence,
                        ifc_model: existing.ifc_model,
                        user: existing.user)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:ifc_model_id]).to be_present
    end
  end

  describe 'scopes' do
    let!(:active_presence) { create(:bim_viewer_presence, last_seen_at: 2.minutes.ago) }
    let!(:stale_presence) { create(:bim_viewer_presence, last_seen_at: 10.minutes.ago) }

    describe '.for_model' do
      it 'returns presence records for specified model' do
        expect(described_class.for_model(ifc_model.id)).to include(presence)
      end
    end

    describe '.for_user' do
      it 'returns presence records for specified user' do
        expect(described_class.for_user(user.id)).to include(presence)
      end
    end

    describe '.active' do
      it 'returns only active presence records (seen within 5 minutes)' do
        expect(described_class.active).to include(active_presence)
        expect(described_class.active).not_to include(stale_presence)
      end
    end

    describe '.recent' do
      it 'orders presence by last_seen_at descending' do
        expect(described_class.recent.first).to eq(active_presence)
      end
    end
  end

  describe '.update_presence' do
    it 'creates new presence if not exists' do
      expect {
        described_class.update_presence(ifc_model: ifc_model, user: user)
      }.to change(described_class, :count).by(1)
    end

    it 'updates existing presence' do
      presence = create(:bim_viewer_presence, ifc_model: ifc_model, user: user, last_seen_at: 10.minutes.ago)

      expect {
        described_class.update_presence(ifc_model: ifc_model, user: user)
      }.not_to change(described_class, :count)

      presence.reload
      expect(presence.last_seen_at).to be > 9.minutes.ago
    end

    it 'updates camera position if provided' do
      camera_pos = { eye: [1, 2, 3], look: [4, 5, 6], up: [0, 0, 1] }

      presence = described_class.update_presence(
        ifc_model: ifc_model,
        user: user,
        camera_position: camera_pos
      )

      expect(presence.camera_position).to eq(camera_pos.stringify_keys)
    end
  end

  describe '.active_viewers' do
    it 'returns list of active users viewing the model' do
      create(:bim_viewer_presence, ifc_model: ifc_model, last_seen_at: 2.minutes.ago)

      viewers = described_class.active_viewers(ifc_model)
      expect(viewers.size).to eq(1)
    end
  end

  describe '.cleanup_stale_presence' do
    it 'removes presence records older than threshold' do
      create(:bim_viewer_presence, last_seen_at: 2.hours.ago)

      expect {
        described_class.cleanup_stale_presence(1.hour.ago)
      }.to change(described_class, :count).by(-1)
    end
  end

  describe '#active?' do
    it 'returns true if last seen within 5 minutes' do
      presence = create(:bim_viewer_presence, last_seen_at: 2.minutes.ago)
      expect(presence.active?).to be true
    end

    it 'returns false if last seen more than 5 minutes ago' do
      presence = create(:bim_viewer_presence, last_seen_at: 10.minutes.ago)
      expect(presence.active?).to be false
    end
  end

  describe '#touch_presence!' do
    it 'updates last_seen_at to current time' do
      presence.update(last_seen_at: 10.minutes.ago)

      presence.touch_presence!
      expect(presence.last_seen_at).to be > 1.minute.ago
    end

    it 'updates camera position if provided' do
      new_camera = { eye: [7, 8, 9], look: [1, 2, 3], up: [0, 1, 0] }

      presence.touch_presence!(camera_position: new_camera)
      expect(presence.camera_position).to eq(new_camera.stringify_keys)
    end
  end

  describe '#to_broadcast' do
    it 'returns presence data for broadcasting' do
      data = presence.to_broadcast

      expect(data[:user_id]).to eq(user.id)
      expect(data[:user_name]).to eq(user.name)
      expect(data[:user_login]).to eq(user.login)
      expect(data[:active]).to be_in([true, false])
    end
  end
end
