#-- encoding: UTF-8
#
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.join(__FILE__, '../csv_exporter')
require File.join(__FILE__, '../pdf_exporter')

class WorkPackage::Exporter

  extend ::WorkPackage::PdfExporter
  extend ::WorkPackage::CsvExporter
end
