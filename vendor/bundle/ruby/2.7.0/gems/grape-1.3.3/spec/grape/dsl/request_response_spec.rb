# frozen_string_literal: true

require 'spec_helper'

module Grape
  module DSL
    module RequestResponseSpec
      class Dummy
        include Grape::DSL::RequestResponse

        def self.set(key, value)
          settings[key.to_sym] = value
        end

        def self.imbue(key, value)
          settings.imbue(key, value)
        end
      end
    end

    describe RequestResponse do
      subject { Class.new(RequestResponseSpec::Dummy) }
      let(:c_type) { 'application/json' }
      let(:format) { 'txt' }

      describe '.default_format' do
        it 'sets the default format' do
          expect(subject).to receive(:namespace_inheritable).with(:default_format, :format)
          subject.default_format :format
        end

        it 'returns the format without paramter' do
          subject.default_format :format

          expect(subject.default_format).to eq :format
        end
      end

      describe '.format' do
        it 'sets a new format' do
          expect(subject).to receive(:namespace_inheritable).with(:format, format.to_sym)
          expect(subject).to receive(:namespace_inheritable).with(:default_error_formatter, Grape::ErrorFormatter::Txt)

          subject.format format
        end
      end

      describe '.formatter' do
        it 'sets the formatter for a content type' do
          expect(subject).to receive(:namespace_stackable).with(:formatters, c_type.to_sym => :formatter)
          subject.formatter c_type, :formatter
        end
      end

      describe '.parser' do
        it 'sets a parser for a content type' do
          expect(subject).to receive(:namespace_stackable).with(:parsers, c_type.to_sym => :parser)
          subject.parser c_type, :parser
        end
      end

      describe '.default_error_formatter' do
        it 'sets a new error formatter' do
          expect(subject).to receive(:namespace_inheritable).with(:default_error_formatter, Grape::ErrorFormatter::Json)
          subject.default_error_formatter :json
        end
      end

      describe '.error_formatter' do
        it 'sets a error_formatter' do
          format = 'txt'
          expect(subject).to receive(:namespace_stackable).with(:error_formatters, format.to_sym => :error_formatter)
          subject.error_formatter format, :error_formatter
        end

        it 'understands syntactic sugar' do
          expect(subject).to receive(:namespace_stackable).with(:error_formatters, format.to_sym => :error_formatter)
          subject.error_formatter format, with: :error_formatter
        end
      end

      describe '.content_type' do
        it 'sets a content type for a format' do
          expect(subject).to receive(:namespace_stackable).with(:content_types, format.to_sym => c_type)
          subject.content_type format, c_type
        end
      end

      describe '.content_types' do
        it 'returns all content types' do
          expect(subject.content_types).to eq(xml: 'application/xml',
                                              serializable_hash: 'application/json',
                                              json: 'application/json',
                                              txt: 'text/plain',
                                              binary: 'application/octet-stream')
        end
      end

      describe '.default_error_status' do
        it 'sets a default error status' do
          expect(subject).to receive(:namespace_inheritable).with(:default_error_status, 500)
          subject.default_error_status 500
        end
      end

      describe '.rescue_from' do
        describe ':all' do
          it 'sets rescue all to true' do
            expect(subject).to receive(:namespace_inheritable).with(:rescue_all, true)
            expect(subject).to receive(:namespace_inheritable).with(:all_rescue_handler, nil)
            subject.rescue_from :all
          end

          it 'sets given proc as rescue handler' do
            rescue_handler_proc = proc {}
            expect(subject).to receive(:namespace_inheritable).with(:rescue_all, true)
            expect(subject).to receive(:namespace_inheritable).with(:all_rescue_handler, rescue_handler_proc)
            subject.rescue_from :all, rescue_handler_proc
          end

          it 'sets given block as rescue handler' do
            rescue_handler_proc = proc {}
            expect(subject).to receive(:namespace_inheritable).with(:rescue_all, true)
            expect(subject).to receive(:namespace_inheritable).with(:all_rescue_handler, rescue_handler_proc)
            subject.rescue_from :all, &rescue_handler_proc
          end

          it 'sets a rescue handler declared through :with option' do
            with_block = -> { 'hello' }
            expect(subject).to receive(:namespace_inheritable).with(:rescue_all, true)
            expect(subject).to receive(:namespace_inheritable).with(:all_rescue_handler, an_instance_of(Proc))
            subject.rescue_from :all, with: with_block
          end

          it 'abort if :with option value is not Symbol, String or Proc' do
            expect { subject.rescue_from :all, with: 1234 }.to raise_error(ArgumentError, "with: #{integer_class_name}, expected Symbol, String or Proc")
          end

          it 'abort if both :with option and block are passed' do
            expect do
              subject.rescue_from :all, with: -> { 'hello' } do
                error!('bye')
              end
            end.to raise_error(ArgumentError, 'both :with option and block cannot be passed')
          end
        end

        describe ':grape_exceptions' do
          it 'sets rescue all to true' do
            expect(subject).to receive(:namespace_inheritable).with(:rescue_all, true)
            expect(subject).to receive(:namespace_inheritable).with(:rescue_grape_exceptions, true)
            subject.rescue_from :grape_exceptions
          end

          it 'sets rescue_grape_exceptions to true' do
            expect(subject).to receive(:namespace_inheritable).with(:rescue_all, true)
            expect(subject).to receive(:namespace_inheritable).with(:rescue_grape_exceptions, true)
            subject.rescue_from :grape_exceptions
          end
        end

        describe 'list of exceptions is passed' do
          it 'sets hash of exceptions as rescue handlers' do
            expect(subject).to receive(:namespace_reverse_stackable).with(:rescue_handlers, StandardError => nil)
            expect(subject).to receive(:namespace_stackable).with(:rescue_options, {})
            subject.rescue_from StandardError
          end

          it 'rescues only base handlers if rescue_subclasses: false option is passed' do
            expect(subject).to receive(:namespace_reverse_stackable).with(:base_only_rescue_handlers, StandardError => nil)
            expect(subject).to receive(:namespace_stackable).with(:rescue_options, rescue_subclasses: false)
            subject.rescue_from StandardError, rescue_subclasses: false
          end

          it 'sets given proc as rescue handler for each key in hash' do
            rescue_handler_proc = proc {}
            expect(subject).to receive(:namespace_reverse_stackable).with(:rescue_handlers, StandardError => rescue_handler_proc)
            expect(subject).to receive(:namespace_stackable).with(:rescue_options, {})
            subject.rescue_from StandardError, rescue_handler_proc
          end

          it 'sets given block as rescue handler for each key in hash' do
            rescue_handler_proc = proc {}
            expect(subject).to receive(:namespace_reverse_stackable).with(:rescue_handlers, StandardError => rescue_handler_proc)
            expect(subject).to receive(:namespace_stackable).with(:rescue_options, {})
            subject.rescue_from StandardError, &rescue_handler_proc
          end

          it 'sets a rescue handler declared through :with option for each key in hash' do
            with_block = -> { 'hello' }
            expect(subject).to receive(:namespace_reverse_stackable).with(:rescue_handlers, StandardError => an_instance_of(Proc))
            expect(subject).to receive(:namespace_stackable).with(:rescue_options, {})
            subject.rescue_from StandardError, with: with_block
          end
        end
      end

      describe '.represent' do
        it 'sets a presenter for a class' do
          presenter = Class.new
          expect(subject).to receive(:namespace_stackable).with(:representations, ThisClass: presenter)
          subject.represent :ThisClass, with: presenter
        end
      end
    end
  end
end
