# frozen_string_literal: true

require 'spec_helper'

module Grape
  module DSL
    module LoggerSpec
      class Dummy
        extend Grape::DSL::Logger
      end
    end
    describe Logger do
      subject { Class.new(LoggerSpec::Dummy) }
      let(:logger) { double(:logger) }

      describe '.logger' do
        it 'sets a logger' do
          subject.logger logger
          expect(subject.logger).to eq logger
        end

        it 'returns a logger' do
          expect(subject.logger(logger)).to eq logger
        end
      end
    end
  end
end
