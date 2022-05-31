require 'spec_helper'

describe Day, type: :model do
  let(:today) { Date.current }
  let(:first_of_year) { Date.new(2022, 1, 1) }

  subject do
    described_class
    .from_range(from: Date.new(2022, 1, 1), to: Date.new(2022, 2, 1))
    .find(first_of_year.strftime("%Y%m%d").to_i)
  end

  it { is_expected.to be_readonly }
  it { is_expected.to respond_to :id }
  it { is_expected.to respond_to :date }
  it { is_expected.to respond_to :day_of_week }
  it { is_expected.to respond_to :name }

  context 'with a collection' do
    let(:days) { described_class.default_scope }

    it 'returns a default date range' do
      expect(days.minmax.pluck(:date)).to eq(
        [today.at_beginning_of_month, today.next_month.at_end_of_month]
      )
    end

    it 'eager loads week_day relation' do
      expect(days).to(be_all { |d| d.association(:week_day).loaded? })
    end

    it 'eager loads non_working_days relation' do
      expect(days).to(be_all { |d| d.association(:non_working_days).loaded? })
    end

    it 'loads the id attribute' do
      expect(days.first.id).to eq(today.at_beginning_of_month.strftime('%Y%m%d').to_i)
    end

    it 'loads the date attribute' do
      expect(days.first.date).to eq(today.at_beginning_of_month)
    end

    it 'loads the day_of_week attribute' do
      expect(days.first.day_of_week % 7).to eq(today.at_beginning_of_month.wday) # wday is from 0-6
    end

    it 'does not have a name' do
      expect(days.first.name).to be_nil
    end
  end

  context 'with the weekday present' do
    before do
      create(:week_day, day: 6)
    end

    it 'loads the name attribute' do
      expect(subject.name).to eq('Saturday')
    end
  end

  describe '#working' do
    context 'when the week day is non-working' do
      before do
        create(:week_day, day: 6, working: false)
      end

      it 'is false' do
        expect(subject.working).to be_falsy
      end

      context 'with a non-working day' do
        before do
          create(:non_working_day, date: first_of_year)
        end

        it 'is false' do
          expect(subject.working).to be_falsy
        end
      end
    end

    context 'when the week day is working' do
      before do
        create(:week_day, day: 6, working: true)
      end

      it 'is true' do
        expect(subject.working).to be_truthy
      end

      context 'with a non working day' do
        before do
          create(:non_working_day, date: first_of_year)
        end

        it 'is false' do
          expect(subject.working).to be_falsy
        end
      end
    end
  end
end
