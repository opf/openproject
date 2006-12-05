require 'rfpdf'

ActionView::Base::register_template_handler 'rfpdf', RFPDF::View