# frozen_string_literal: true

require 'spec_helper'

describe Grape::Validations::ExceptValuesValidator do
  module ValidationsSpec
    class ExceptValuesModel
      DEFAULT_EXCEPTS = ['invalid-type1', 'invalid-type2', 'invalid-type3'].freeze
      class << self
        attr_accessor :excepts
        def excepts
          @excepts ||= []
          [DEFAULT_EXCEPTS + @excepts].flatten.uniq
        end
      end
    end

    TEST_CASES = {
      req_except: {
        requires: { except_values: ExceptValuesModel.excepts },
        tests: [
          { value: 'invalid-type1', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
          { value: 'invalid-type3', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
          { value: 'valid-type', rc: 200, body: { type: 'valid-type' }.to_json }
        ]
      },
      req_except_hash: {
        requires: { except_values: { value: ExceptValuesModel.excepts } },
        tests: [
          { value: 'invalid-type1', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
          { value: 'invalid-type3', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
          { value: 'valid-type', rc: 200, body: { type: 'valid-type' }.to_json }
        ]
      },
      req_except_custom_message: {
        requires: { except_values: { value: ExceptValuesModel.excepts, message: 'is not allowed' } },
        tests: [
          { value: 'invalid-type1', rc: 400, body: { error: 'type is not allowed' }.to_json },
          { value: 'invalid-type3', rc: 400, body: { error: 'type is not allowed' }.to_json },
          { value: 'valid-type', rc: 200, body: { type: 'valid-type' }.to_json }
        ]
      },
      req_except_no_value: {
        requires: { except_values: { message: 'is not allowed' } },
        tests: [
          { value: 'invalid-type1', rc: 200, body: { type: 'invalid-type1' }.to_json }
        ]
      },
      req_except_empty: {
        requires: { except_values: [] },
        tests: [
          { value: 'invalid-type1', rc: 200, body: { type: 'invalid-type1' }.to_json }
        ]
      },
      req_except_lambda: {
        requires: { except_values: -> { ExceptValuesModel.excepts } },
        add_excepts: ['invalid-type4'],
        tests: [
          { value: 'invalid-type1', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
          { value: 'invalid-type4', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
          { value: 'valid-type', rc: 200, body: { type: 'valid-type' }.to_json }
        ]
      },
      req_except_lambda_custom_message: {
        requires: { except_values: { value: -> { ExceptValuesModel.excepts }, message: 'is not allowed' } },
        add_excepts: ['invalid-type4'],
        tests: [
          { value: 'invalid-type1', rc: 400, body: { error: 'type is not allowed' }.to_json },
          { value: 'invalid-type4', rc: 400, body: { error: 'type is not allowed' }.to_json },
          { value: 'valid-type', rc: 200, body: { type: 'valid-type' }.to_json }
        ]
      },
      opt_except_default: {
        optional: { except_values: ExceptValuesModel.excepts, default: 'valid-type2' },
        tests: [
          { value: 'invalid-type1', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
          { value: 'invalid-type3', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
          { value: 'valid-type', rc: 200, body: { type: 'valid-type' }.to_json },
          { rc: 200, body: { type: 'valid-type2' }.to_json }
        ]
      },
      opt_except_lambda_default: {
        optional: { except_values: -> { ExceptValuesModel.excepts }, default: 'valid-type2' },
        tests: [
          { value: 'invalid-type1', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
          { value: 'invalid-type3', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
          { value: 'valid-type', rc: 200, body: { type: 'valid-type' }.to_json },
          { rc: 200, body: { type: 'valid-type2' }.to_json }
        ]
      },
      req_except_type_coerce: {
        requires: { type: Integer, except_values: [10, 11] },
        tests: [
          { value: 'invalid-type1', rc: 400, body: { error: 'type is invalid' }.to_json },
          { value: 11, rc: 400, body: { error: 'type has a value not allowed' }.to_json },
          { value: '11', rc: 400, body: { error: 'type has a value not allowed' }.to_json },
          { value: '3', rc: 200, body: { type: 3 }.to_json },
          { value: 3, rc: 200, body: { type: 3 }.to_json }
        ]
      },
      opt_except_type_coerce_default: {
        optional: { type: Integer, except_values: [10, 11], default: 12 },
        tests: [
          { value: 'invalid-type1', rc: 400, body: { error: 'type is invalid' }.to_json },
          { value: 10, rc: 400, body: { error: 'type has a value not allowed' }.to_json },
          { value: '3', rc: 200, body: { type: 3 }.to_json },
          { value: 3, rc: 200, body: { type: 3 }.to_json },
          { rc: 200, body: { type: 12 }.to_json }
        ]
      },
      opt_except_array_type_coerce_default: {
        optional: { type: Array[Integer], except_values: [10, 11], default: 12 },
        tests: [
          { value: 'invalid-type1', rc: 400, body: { error: 'type is invalid' }.to_json },
          { value: 10, rc: 400, body: { error: 'type is invalid' }.to_json },
          { value: [10], rc: 400, body: { error: 'type has a value not allowed' }.to_json },
          { value: ['3'], rc: 200, body: { type: [3] }.to_json },
          { value: [3], rc: 200, body: { type: [3] }.to_json },
          { rc: 200, body: { type: 12 }.to_json }
        ]
      },
      req_except_range: {
        optional: { type: Integer, except_values: 10..12 },
        tests: [
          { value: 11, rc: 400, body: { error: 'type has a value not allowed' }.to_json },
          { value: 13, rc: 200, body: { type: 13 }.to_json }
        ]
      }
    }.freeze

    module ExceptValidatorSpec
      class API < Grape::API
        default_format :json

        TEST_CASES.each_with_index do |(k, v), _i|
          params do
            requires :type, v[:requires] if v.key? :requires
            optional :type, v[:optional] if v.key? :optional
          end
          get k do
            { type: params[:type] }
          end
        end
      end
    end
  end

  it 'raises IncompatibleOptionValues on a default value in exclude' do
    subject = Class.new(Grape::API)
    expect do
      subject.params do
        optional :type, except_values: ValidationsSpec::ExceptValuesModel.excepts,
                        default: ValidationsSpec::ExceptValuesModel.excepts.sample
      end
    end.to raise_error Grape::Exceptions::IncompatibleOptionValues
  end

  it 'raises IncompatibleOptionValues when a default array has excluded values' do
    subject = Class.new(Grape::API)
    expect do
      subject.params do
        optional :type, type: Array[Integer],
                        except_values: 10..12,
                        default: [8, 9, 10]
      end
    end.to raise_error Grape::Exceptions::IncompatibleOptionValues
  end

  it 'raises IncompatibleOptionValues when type is incompatible with values array' do
    subject = Class.new(Grape::API)
    expect do
      subject.params { optional :type, except_values: ['valid-type1', 'valid-type2', 'valid-type3'], type: Symbol }
    end.to raise_error Grape::Exceptions::IncompatibleOptionValues
  end

  def app
    ValidationsSpec::ExceptValidatorSpec::API
  end

  ValidationsSpec::TEST_CASES.each_with_index do |(k, v), i|
    v[:tests].each do |t|
      it "#{i}: #{k} - #{t[:value]}" do
        ValidationsSpec::ExceptValuesModel.excepts = v[:add_excepts] if v.key? :add_excepts
        body = {}
        body[:type] = t[:value] if t.key? :value
        get k.to_s, **body
        expect(last_response.status).to eq t[:rc]
        expect(last_response.body).to eq t[:body]
        ValidationsSpec::ExceptValuesModel.excepts = nil
      end
    end
  end
end
