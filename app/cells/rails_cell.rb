class RailsCell < Cell::ViewModel
  include Escaped
  include ApplicationHelper
  include ActionView::Helpers::TranslationHelper

  self.view_paths = ['app/cells/views']

  # We don't include ActionView::Helpers wholesale because
  # this would override Cell's own render method and
  # subsequently break everything.

  def self.options(*names)
    names.each do |name|
      define_method(name) do
        options[name]
      end
    end
  end

  def show
    render
  end

  def controller
    context[:controller]
  end
end
