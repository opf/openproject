require 'rails_helper'

RSpec.describe WeekDay, type: :model do
  describe '#name' do
    it 'returns the translated week day name' do
      expect(described_class.create(day: 1).name).to eq('Monday')
      expect(described_class.create(day: 7).name).to eq('Sunday')
      I18n.with_locale(:de) do
        expect(described_class.create(day: 3).name).to eq('Mittwoch')
        expect(described_class.create(day: 4).name).to eq('Donnerstag')
      end
    end
  end
end
