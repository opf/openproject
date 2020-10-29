# frozen_string_literal: true

require 'spec_helper'

module Grape
  module DSL
    module HeadersSpec
      class Dummy
        include Grape::DSL::Headers
      end
    end
    describe Headers do
      subject { HeadersSpec::Dummy.new }

      describe '#header' do
        describe 'set' do
          before do
            subject.header 'Name', 'Value'
          end

          it 'returns value' do
            expect(subject.header['Name']).to eq 'Value'
            expect(subject.header('Name')).to eq 'Value'
          end
        end

        it 'returns nil' do
          expect(subject.header['Name']).to be nil
          expect(subject.header('Name')).to be nil
        end
      end
    end
  end
end
