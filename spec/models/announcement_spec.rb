require 'spec_helper'

describe Announcement, type: :model do
  it do is_expected.to respond_to :text end
  it do is_expected.to respond_to :text= end
  it do is_expected.to respond_to :show_until end
  it do is_expected.to respond_to :show_until= end
  it do is_expected.to respond_to :active? end
  it do is_expected.to respond_to :active= end

  describe 'class methods' do
    describe '#only_one' do
      context 'WHEN no announcement exists' do
        it do expect(Announcement.only_one.text).to eql 'Announcement' end
        it do expect(Announcement.only_one.show_until).to eql(Date.today + 14.days) end
        it { expect(Announcement.only_one.active).to eql false }
      end

      context 'WHEN an announcement exists' do
        let!(:announcement) { FactoryBot.create :announcement }
        it 'returns the true one announcement' do
          expect(Announcement.only_one).to eql announcement
        end
      end
    end

    describe '#active_and_current' do
      describe 'WHEN no announcement is active' do
        let!(:announcement) { FactoryBot.create(:inactive_announcement) }

        it 'returns no announcement' do
          expect(Announcement.active_and_current).to be_nil
        end
      end

      describe 'WHEN the one announcement is active and today is before show_until' do
        let!(:announcement) {
          FactoryBot.create(:active_announcement, show_until: Date.today + 14.days)
        }

        it 'returns that announcement' do
          expect(Announcement.active_and_current).to eql announcement
        end
      end

      describe 'WHEN the one announcement is active and today is after show_until' do
        let!(:announcement) {
          FactoryBot.create(:active_announcement, show_until: Date.today - 14.days)
        }

        it 'returns no announcement' do
          expect(Announcement.active_and_current).to be_nil
        end
      end

      describe 'WHEN the one announcement is active and today equals show_until' do
        let!(:announcement) {
          FactoryBot.create(:active_announcement, show_until: Date.today)
        }
        it 'returns that announcement' do
          expect(Announcement.active_and_current).to eql announcement
        end
      end
    end

    describe 'instance methods' do
      describe '#active_and_current?' do
        describe 'WHEN the announcement is not active' do
          let(:announcement) { FactoryBot.build(:inactive_announcement) }

          it { expect(announcement.active_and_current?).to be_falsey }
        end

        describe 'WHEN the announcement is active and today is before show_until' do
          let(:announcement) {
            FactoryBot.build(:active_announcement, show_until: Date.today + 14.days)
          }

          it { expect(announcement.active_and_current?).to be_truthy }
        end

        describe 'WHEN the announcement is active and today is after show_until' do
          let!(:announcement) {
            FactoryBot.create(:active_announcement, show_until: Date.today - 14.days)
          }

          it { expect(announcement.active_and_current?).to be_falsey }
        end

        describe 'WHEN the announcement is active and today equals show_until' do
          let!(:announcement) {
            FactoryBot.build(:active_announcement, show_until: Date.today)
          }

          it { expect(announcement.active_and_current?).to be_truthy }
        end
      end
    end
  end
end
