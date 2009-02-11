require 'test/unit'

require "openid/urinorm"
require "testutil"

class URINormTestCase < Test::Unit::TestCase
  include OpenID::TestDataMixin

  def test_normalize
    lines = read_data_file('urinorm.txt')

    while lines.length > 0

      case_name = lines.shift.strip
      actual = lines.shift.strip
      expected = lines.shift.strip
      _newline = lines.shift

      if expected == 'fail'
        begin
          OpenID::URINorm.urinorm(actual)
        rescue URI::InvalidURIError
          assert true
        else
          raise 'Should have gotten URI error'
        end
      else
        normalized = OpenID::URINorm.urinorm(actual)
        assert_equal(expected, normalized, case_name)
      end
    end
  end

end

