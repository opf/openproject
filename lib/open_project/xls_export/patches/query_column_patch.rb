module OpenProject::XlsExport::Patches::QueryColumnPatch
  def self.included(base) # :nodoc:
    base.class_eval do
      include InstanceMethods
    end
  end

  module InstanceMethods
    ##
    # Returns the key (symbol) of the formatter to be used.
    # E.g. :default, :time, :cost
    #
    # Available keys: OpenProject::XlsExport::Formatters.keys
    def xls_formatter
      nil
    end

    def xls_value(work_package)
      value work_package
    end
  end
end
