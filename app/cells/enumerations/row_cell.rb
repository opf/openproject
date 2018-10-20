module Enumerations
  class RowCell < ::RowCell
    include ::IconsHelper
    include ::ColorsHelper
    include ReorderLinksHelper

    def enumeration
      model
    end

    def name
      link_to h(enumeration.name), edit_enumeration_path(enumeration)
    end

    def is_default
      if enumeration.is_default?
        op_icon 'icon icon-checkmark'
      end
    end

    def color
      icon_for_color enumeration.color
    end

    def active
      if enumeration.active?
        op_icon 'icon icon-checkmark'
      end
    end

    def sort
      reorder_links('enumeration', { action: 'update', id: enumeration }, method: :put)
    end

    def button_links
      [
        delete_link(enumeration_path(enumeration))
      ]
    end
  end
end
