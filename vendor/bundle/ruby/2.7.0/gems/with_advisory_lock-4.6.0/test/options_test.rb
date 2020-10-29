require 'minitest_helper'

describe 'options parsing' do
  def parse_options(options)
    WithAdvisoryLock::Base.new(mock, mock, options)
  end

  specify 'defaults (empty hash)' do
    impl = parse_options({})
    impl.timeout_seconds.must_be_nil
    impl.shared.must_equal false
    impl.transaction.must_equal false
  end

  specify 'nil sets timeout to nil' do
    impl = parse_options(nil)
    impl.timeout_seconds.must_be_nil
    impl.shared.must_equal false
    impl.transaction.must_equal false
  end

  specify 'integer sets timeout to value' do
    impl = parse_options(42)
    impl.timeout_seconds.must_equal 42
    impl.shared.must_equal false
    impl.transaction.must_equal false
  end

  specify 'hash with invalid key errors' do
    proc {
      parse_options(foo: 42)
    }.must_raise ArgumentError
  end

  specify 'hash with timeout_seconds sets timeout to value' do
    impl = parse_options(timeout_seconds: 123)
    impl.timeout_seconds.must_equal 123
    impl.shared.must_equal false
    impl.transaction.must_equal false
  end

  specify 'hash with shared option sets shared to true' do
    impl = parse_options(shared: true)
    impl.timeout_seconds.must_be_nil
    impl.shared.must_equal true
    impl.transaction.must_equal false
  end

  specify 'hash with transaction option set transaction to true' do
    impl = parse_options(transaction: true)
    impl.timeout_seconds.must_be_nil
    impl.shared.must_equal false
    impl.transaction.must_equal true
  end

  specify 'hash with multiple keys sets options' do
    foo = mock
    bar = mock
    impl = parse_options(timeout_seconds: foo, shared: bar)
    impl.timeout_seconds.must_equal foo
    impl.shared.must_equal bar
    impl.transaction.must_equal false
  end
end
