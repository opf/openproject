#!/usr/bin/env ruby
# TestFormat -- Spreadsheet -- 06.11.2012 -- mina.git@naguib.ca

$: << File.expand_path('../lib', File.dirname(__FILE__))

require 'test/unit'
require 'spreadsheet'

module Spreadsheet
  class TestFormat < Test::Unit::TestCase
    def setup
      @format = Format.new
    end
    def test_date?
      assert_equal false, @format.date?
      @format.number_format = "hms"
      assert_equal false, @format.date?
      @format.number_format = "Y"
      assert_equal true, @format.date?
      @format.number_format = "YMD"
      assert_equal true, @format.date?
      @format.number_format = "[$-409]YMD"
      assert_equal true, @format.date?
      @format.number_format = "\\$#,##0.00_);[RED]\"($\"#,##0.00\\)"
      assert_equal false, @format.date?
      @format.number_format = "0.00;[RED]\\-0.00"
      assert_equal false, @format.date?
      @format.number_format = "[$-C0A]dd\\-mmm\\-yy"
      assert_equal true, @format.date?
    end
    def test_date_or_time?
      assert_equal false, @format.date_or_time?
      @format.number_format = "hms"
      assert_equal true, @format.date_or_time?
      @format.number_format = "YMD"
      assert_equal true, @format.date_or_time?
      @format.number_format = "hmsYMD"
      assert_equal true, @format.date_or_time?
      @format.number_format = "[$-409]hmsYMD"
      assert_equal true, @format.date_or_time?
      @format.number_format = "\\$#,##0.00_);[RED]\"($\"#,##0.00\\)"
      assert_equal false, @format.date_or_time?
      @format.number_format = "0.00;[RED]\\-0.00)"
      assert_equal false, @format.date_or_time?
    end
    def test_datetime?
      assert_equal false, @format.datetime?
      @format.number_format = "H"
      assert_equal false, @format.datetime?
      @format.number_format = "S"
      assert_equal false, @format.datetime?
      @format.number_format = "Y"
      assert_equal false, @format.datetime?
      @format.number_format = "HSYMD"
      assert_equal true, @format.datetime?
      @format.number_format = "\\$#,##0.00_);[RED]\"($\"#,##0.00\\)"
      assert_equal false, @format.datetime?
      @format.number_format = "0.00;[RED]\\-0.00)"
      assert_equal false, @format.datetime?
    end
    def test_time?
      assert_equal false, @format.time?
      @format.number_format = "YMD"
      assert_equal false, @format.time?
      @format.number_format = "hmsYMD"
      assert_equal true, @format.time?
      @format.number_format = "h"
      assert_equal true, @format.time?
      @format.number_format = "hm"
      assert_equal true, @format.time?
      @format.number_format = "[$-409]hms"
      assert_equal true, @format.time?
      @format.number_format = "hms"
      assert_equal true, @format.time?
      @format.number_format = "\\$#,##0.00_);[RED]\"($\"#,##0.00\\)"
      assert_equal false, @format.time?
      @format.number_format = "0.00;[RED]\\-0.00)"
      assert_equal false, @format.time?
    end
		def test_borders?
			assert_equal [:none, :none, :none, :none], @format.border
			@format.border = :thick
			assert_equal [:thick, :thick, :thick, :thick], @format.border
			@format.left = :hair
			assert_equal [:thick, :thick, :thick, :hair], @format.border
			@format.right = :hair
			assert_equal [:thick, :thick, :hair, :hair], @format.border
			@format.top = :hair
			assert_equal [:thick, :hair, :hair, :hair], @format.border
			@format.bottom = :hair
			assert_equal [:hair, :hair, :hair, :hair], @format.border
			assert_raises(ArgumentError) do			
				@format.bottom = :bogus
			end
			assert_equal [:black, :black, :black, :black], @format.border_color
			@format.border_color = :green
			assert_equal [:green, :green, :green, :green], @format.border_color
			@format.left_color = :red
			assert_equal [:green, :green, :green, :red], @format.border_color
			@format.right_color = :red
			assert_equal [:green, :green, :red, :red], @format.border_color
			@format.top_color = :red
			assert_equal [:green, :red, :red, :red], @format.border_color
			@format.bottom_color = :red
			assert_equal [:red, :red, :red, :red], @format.border_color
			assert_raises(ArgumentError) do			
				@format.bottom_color = :bogus
			end
		end
  end
end
