require 'support/components/ng_select_autocomplete_helpers'
require_relative './edit_field'

class ProjectStatusField < EditField
  include ::Components::NgSelectAutocompleteHelpers

  def input_selector
    '.ng-select.project-status'
  end

  def field_type
    input_selector
  end

  def set_to(status_name)
    page.find('.ng-input input').set("#{status_name}\n")
  end
end
