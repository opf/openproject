require "minitest/autorun"
require "cells"
require "cells-erb"

Cell::ViewModel.send(:include, Cell::Erb) if Cell.const_defined?(:Erb) # FIXME: should happen in inititalizer.

MiniTest::Spec.class_eval do
  include Cell::Testing
end

class BassistCell < Cell::ViewModel
  self.view_paths = ['test/fixtures']
end
