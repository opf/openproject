# frozen_string_literal: true

# measurements.rb: Conversions from other measurements to PDF points
#
# Copyright December 2008, Florian Witteler.  All Rights Reserved.
#

# rubocop: disable Naming/MethodParameterName
module Prawn
  # @group Stable API

  module Measurements
    # metric conversions
    def cm2mm(cm)
      cm * 10
    end

    def dm2mm(dm)
      dm * 100
    end

    def m2mm(m)
      m * 1000
    end

    # imperial conversions
    # from http://en.wikipedia.org/wiki/Imperial_units
    def ft2in(ft)
      ft * 12
    end

    def yd2in(yd)
      yd * 36
    end

    # PostscriptPoint-converisons
    def pt2pt(pt)
      pt
    end

    def in2pt(inch)
      inch * 72
    end

    def ft2pt(ft)
      in2pt(ft2in(ft))
    end

    def yd2pt(yd)
      in2pt(yd2in(yd))
    end

    def mm2pt(mm)
      mm * (72 / 25.4)
    end

    def cm2pt(cm)
      mm2pt(cm2mm(cm))
    end

    def dm2pt(dm)
      mm2pt(dm2mm(dm))
    end

    def m2pt(m)
      mm2pt(m2mm(m))
    end

    def pt2mm(pt)
      pt * 1 / mm2pt(1) # (25.4 / 72)
    end
  end
end
# rubocop: enable Naming/MethodParameterName
