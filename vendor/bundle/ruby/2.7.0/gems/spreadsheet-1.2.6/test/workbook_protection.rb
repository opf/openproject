#!/usr/bin/env ruby

$: << File.expand_path('../lib', File.dirname(__FILE__))

require 'test/unit'
require 'spreadsheet'

module Spreadsheet
  module Excel
    class TestWorkbook < Test::Unit::TestCase
      def test_password_hashing
        hashing_module = Spreadsheet::Excel::Password
        # Some examples found on the web
        assert_equal(0xFEF1, hashing_module.password_hash('abcdefghij'))
        assert_equal(hashing_module.password_hash('test'), hashing_module.password_hash('zzyw'))
      end
    end
  end
end
