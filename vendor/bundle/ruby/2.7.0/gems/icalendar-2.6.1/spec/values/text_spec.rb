require 'spec_helper'

describe Icalendar::Values::Text do

  subject { described_class.new value }
  let(:unescaped) { "This \\ that, semi; colons\r\nAnother line: \"why not?\"" }
  let(:escaped) { 'This \\\\ that\, semi\; colons\nAnother line: "why not?"' }

  describe '#value_ical' do
    let(:value) { unescaped }
    it 'escapes \ , ; NL' do
      expect(subject.value_ical).to eq escaped
    end
  end

  describe 'unescapes in initializer' do
    context 'given escaped version' do
      let(:unescaped_no_cr) { unescaped.gsub "\r", '' }
      let(:value) { escaped }
      it 'removes escaping' do
        expect(subject.value).to eq unescaped_no_cr
      end
    end

    context 'given unescaped version' do
      let(:value) { unescaped }
      it 'does not try to double unescape' do
        expect(subject.value).to eq unescaped
      end
    end
  end

  describe 'escapes parameter text properly' do
    subject { described_class.new escaped, {'param' => param_value} }
    context 'single value, no special characters' do
      let(:param_value) { 'HelloWorld' }
      it 'does not wrap param in double quotes' do
        expect(subject.params_ical).to eq %(;PARAM=HelloWorld)
      end
    end
    context 'single value, special characters' do
      let(:param_value) { 'Hello:World' }
      it 'wraps param value in double quotes' do
        expect(subject.params_ical).to eq %(;PARAM="Hello:World")
      end
    end
    context 'single value, double quotes' do
      let(:param_value) { 'Hello "World"' }
      it 'replaces double quotes with single' do
        expect(subject.params_ical).to eq %(;PARAM=Hello 'World')
      end
    end
    context 'multiple values, no special characters' do
      let(:param_value) { ['HelloWorld', 'GoodbyeMoon'] }
      it 'joins with comma' do
        expect(subject.params_ical).to eq %(;PARAM=HelloWorld,GoodbyeMoon)
      end
    end
    context 'multiple values, with special characters' do
      let(:param_value) { ['Hello, World', 'GoodbyeMoon'] }
      it 'quotes values with special characters, joins with comma' do
        expect(subject.params_ical).to eq %(;PARAM="Hello, World",GoodbyeMoon)
      end
    end
    context 'multiple values, double quotes' do
      let(:param_value) { ['Hello, "World"', 'GoodbyeMoon'] }
      it 'replaces double quotes with single' do
        expect(subject.params_ical).to eq %(;PARAM="Hello, 'World'",GoodbyeMoon)
      end
    end
    context 'nil value' do
      let(:param_value) { nil }
      it 'trats nil as blank' do
        expect(subject.params_ical).to eq %(;PARAM=)
      end
    end
  end
end
