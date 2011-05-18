require 'prawn/measurement_extensions'

module TaskboardCard
  module Measurement
    def self.included(base)
      base.extend(ClassMethods)
    end


    module ClassMethods
      def to_pts(v)
        return if v.nil?

        if v =~ /[a-z]{2}$/i
          units = v[-2, 2].downcase
          v = v[0..-3]
        else
          units = 'pt'
        end

        v = "#{v}0" if v =~ /\.$/

        return Float(v).mm if units == 'mm'
        return Float(v).cm if units == 'cm'
        return Float(v).in if units == 'in'
        return Float(v).pt if units == 'pt'
        raise "Unexpected units '#{units}'"
      end
    end
  end
end