require 'rails_helper'

RSpec.describe Notifications::CleanupJob, type: :job do
  let(:job) { described_class.new }

  describe 'with default period', with_settings: { notification_retention_period_days: 30 } do
    let!(:old_notification) { FactoryBot.create :notification }
    let!(:new_notification) { FactoryBot.create :notification }

    it 'removes any older event' do
      old_notification.update_column(:updated_at, 31.days.ago)

      expect { job.perform }.to change { Notification.count }.from(2).to(1)

      expect { old_notification.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
