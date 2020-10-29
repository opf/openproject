# frozen_string_literal: true

Shindo.tests('Fog::Schema::DataValidator', 'meta') do

  validator = Fog::Schema::DataValidator.new

  tests('#validate') do
    tests('returns true') do
      returns(true, 'when value matches schema expectation') do
        validator.validate({ 'key' => 'Value' }, 'key' => String)
      end

      returns(true, 'when values within an array all match schema expectation') do
        validator.validate({ 'key' => [1, 2] }, 'key' => [Integer])
      end

      returns(true, 'when nested values match schema expectation') do
        validator.validate({ 'key' => { nested_key: 'Value' } }, 'key' => { nested_key: String })
      end

      returns(true, 'when collection of values all match schema expectation') do
        validator.validate([{ 'key' => 'Value' }, 'key' => 'Value'], [{ 'key' => String }])
      end

      returns(true, 'when collection is empty although schema covers optional members') do
        validator.validate([], [{ 'key' => String }])
      end

      returns(true, 'when additional keys are passed and not strict') do
        validator.validate({ 'key' => 'Value', extra: 'Bonus' }, { 'key' => String }, allow_extra_keys: true)
      end

      returns(true, 'when value is nil and schema expects NilClass') do
        validator.validate({ 'key' => nil }, 'key' => NilClass)
      end

      returns(true, 'when value and schema match as hashes') do
        validator.validate({}, {})
      end

      returns(true, 'when value and schema match as arrays') do
        validator.validate([], [])
      end

      returns(true, 'when value is a Time') do
        validator.validate({ 'time' => Time.now }, 'time' => Time)
      end

      returns(true, 'when key is missing but value should be NilClass (#1477)') do
        validator.validate({}, { 'key' => NilClass }, allow_optional_rules: true)
      end

      returns(true, 'when key is missing but value is nullable (#1477)') do
        validator.validate({}, { 'key' => Fog::Nullable::String }, allow_optional_rules: true)
      end
    end

    tests('returns false') do
      returns(false, 'when value does not match schema expectation') do
        validator.validate({ 'key' => nil }, 'key' => String)
      end

      returns(false, 'when key formats do not match') do
        validator.validate({ 'key' => 'Value' }, key: String)
      end

      returns(false, 'when additional keys are passed and strict') do
        validator.validate({ 'key' => 'Missing' }, {})
      end

      returns(false, 'when some keys do not appear') do
        validator.validate({}, 'key' => String)
      end

      returns(false, 'when collection contains a member that does not match schema') do
        validator.validate([{ 'key' => 'Value' }, 'key' => 5], ['key' => String])
      end

      returns(false, 'when collection has multiple schema patterns') do
        validator.validate([{ 'key' => 'Value' }], [{ 'key' => Integer }, { 'key' => String }])
      end

      returns(false, 'when hash and array are compared') do
        validator.validate({}, [])
      end

      returns(false, 'when array and hash are compared') do
        validator.validate([], {})
      end

      returns(false, 'when a hash is expected but another data type is found') do
        validator.validate({ 'key' => { nested_key: [] } }, 'key' => { nested_key: {} })
      end

      returns(false, 'when key is missing but value should be NilClass (#1477)') do
        validator.validate({}, { 'key' => NilClass }, allow_optional_rules: false)
      end

      returns(false, 'when key is missing but value is nullable (#1477)') do
        validator.validate({}, { 'key' => Fog::Nullable::String }, allow_optional_rules: false)
      end
    end
  end
end
