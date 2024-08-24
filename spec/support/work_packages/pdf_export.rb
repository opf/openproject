require "spec_helper"
require "pdf/inspector"

module PDFExportSpecUtils
  def column_title(column_name)
    label_title(column_name).upcase
  end

  def label_title(column_name)
    WorkPackage.human_attribute_name(column_name)
  end
end
