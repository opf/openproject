#-- encoding: UTF-8
module RFPDF
  module ActionController

    DEFAULT_RFPDF_OPTIONS = {:inline=>true}
      
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def rfpdf(options)
          rfpdf_options = breakdown_rfpdf_options options
          write_inheritable_hash(:rfpdf, rfpdf_options)
        end

      private

        def breakdown_rfpdf_options(options)
          rfpdf_options = options.dup
          rfpdf_options
        end
      end

      def rfpdf(options)
        @rfpdf_options ||= DEFAULT_RFPDF_OPTIONS.dup
        @rfpdf_options.merge! options
      end


    private

      def compute_rfpdf_options
        @rfpdf_options ||= DEFAULT_RFPDF_OPTIONS.dup
        @rfpdf_options.merge!(self.class.read_inheritable_attribute(:rfpdf) || {}) {|k,o,n| o}
        @rfpdf_options
      end
  end
end


