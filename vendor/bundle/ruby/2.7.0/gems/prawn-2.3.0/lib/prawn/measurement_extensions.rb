# frozen_string_literal: true

# measurement_extensions.rb: Core extensions for Prawn::Measurements
#
# Copyright December 2008, Florian Witteler.  All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.

require_relative 'measurements'

# @group Stable API

class Numeric
  include Prawn::Measurements
  # prawns' basic unit is PostScript-Point
  # 72 points per inch

  # @group Experimental API

  def mm
    mm2pt(self)
  end

  def cm
    cm2pt(self)
  end

  def dm
    dm2pt(self)
  end

  def m
    m2pt(self)
  end

  def in
    in2pt(self)
  end

  def yd
    yd2pt(self)
  end

  def ft
    ft2pt(self)
  end

  def pt
    pt2pt(self)
  end
end
