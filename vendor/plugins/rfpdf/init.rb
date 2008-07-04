require 'rfpdf'

begin
  ActionView::Template::register_template_handler 'rfpdf', RFPDF::View
rescue NameError
  # Rails < 2.1
  RFPDF::View.backward_compatibility_mode = true
  ActionView::Base::register_template_handler 'rfpdf', RFPDF::View
end
