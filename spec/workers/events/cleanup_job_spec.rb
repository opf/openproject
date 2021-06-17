require 'rails_helper'

RSpec.describe Events::CleanupJob, type: :job do
  let(:job) { described_class.new }

  describe 'with default period', with_settings: { event_retention_period_days: 30 } do
    let!(:old_event) { FactoryBot.create :event }
    let!(:new_event) { FactoryBot.create :event }

    it 'removes any older event' do
      old_event.update_column(:updated_at, 31.days.ago)

      expect { job.perform }.to change { Event.count }.from(2).to(1)

      expect { old_event.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
