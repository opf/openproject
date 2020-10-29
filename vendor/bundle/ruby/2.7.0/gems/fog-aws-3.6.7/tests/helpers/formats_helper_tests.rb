Shindo.tests('test_helper', 'meta') do

  tests('comparing welcome data against schema') do
    data = { welcome: 'Hello' }
    data_matches_schema(welcome: String) { data }
  end

  tests('#data_matches_schema') do
    tests('when value matches schema expectation') do
      data_matches_schema('key' => String) { { 'key' => 'Value' } }
    end

    tests('when values within an array all match schema expectation') do
      data_matches_schema('key' => [Integer]) { { 'key' => [1, 2] } }
    end

    tests('when nested values match schema expectation') do
      data_matches_schema('key' => { nested_key: String }) { { 'key' => { nested_key: 'Value' } } }
    end

    tests('when collection of values all match schema expectation') do
      data_matches_schema([{ 'key' => String }]) { [{ 'key' => 'Value' }, { 'key' => 'Value' }] }
    end

    tests('when collection is empty although schema covers optional members') do
      data_matches_schema([{ 'key' => String }], allow_optional_rules: true) { [] }
    end

    tests('when additional keys are passed and not strict') do
      data_matches_schema({ 'key' => String }, allow_extra_keys: true) { { 'key' => 'Value', extra: 'Bonus' } }
    end

    tests('when value is nil and schema expects NilClass') do
      data_matches_schema('key' => NilClass) { { 'key' => nil } }
    end

    tests('when value and schema match as hashes') do
      data_matches_schema({}) { {} }
    end

    tests('when value and schema match as arrays') do
      data_matches_schema([]) { [] }
    end

    tests('when value is a Time') do
      data_matches_schema('time' => Time) { { 'time' => Time.now } }
    end

    tests('when key is missing but value should be NilClass (#1477)') do
      data_matches_schema({ 'key' => NilClass }, allow_optional_rules: true) { {} }
    end

    tests('when key is missing but value is nullable (#1477)') do
      data_matches_schema({ 'key' => Fog::Nullable::String }, allow_optional_rules: true) { {} }
    end
  end

  tests('#formats backwards compatible changes') do
    tests('when value matches schema expectation') do
      formats('key' => String) { { 'key' => 'Value' } }
    end

    tests('when values within an array all match schema expectation') do
      formats('key' => [Integer]) { { 'key' => [1, 2] } }
    end

    tests('when nested values match schema expectation') do
      formats('key' => { nested_key: String }) { { 'key' => { nested_key: 'Value' } } }
    end

    tests('when collection of values all match schema expectation') do
      formats([{ 'key' => String }]) { [{ 'key' => 'Value' }, { 'key' => 'Value' }] }
    end

    tests('when collection is empty although schema covers optional members') do
      formats([{ 'key' => String }]) { [] }
    end

    tests('when additional keys are passed and not strict') do
      formats({ 'key' => String }, false) { { 'key' => 'Value', :extra => 'Bonus' } }
    end

    tests('when value is nil and schema expects NilClass') do
      formats('key' => NilClass) { { 'key' => nil } }
    end

    tests('when value and schema match as hashes') do
      formats({}) { {} }
    end

    tests('when value and schema match as arrays') do
      formats([]) { [] }
    end

    tests('when value is a Time') do
      formats('time' => Time) { { 'time' => Time.now } }
    end

    tests('when key is missing but value should be NilClass (#1477)') do
      formats('key' => NilClass) { {} }
    end

    tests('when key is missing but value is nullable (#1477)') do
      formats('key' => Fog::Nullable::String) { {} }
    end
  end
end
