require_dependency 'enumerations/row_cell'

module Enumerations
  class TableCell < ::TableCell

    def initial_sort
      %i[id asc]
    end

    def sortable?
      false
    end

    def with_colors
      model.colored?
    end

    def columns
      %i[name is_default active sort].tap do |default|
        if with_colors
          default.insert 3, :color
        end
      end
    end

    def inline_create_link
      link_to new_enumeration_path(type: model.name),
              aria: { label: t(:label_enumeration_new) },
              class: 'wp-inline-create--add-link',
              title: t(:label_enumeration_new) do
        op_icon('icon icon-add')
      end
    end

    def empty_row_message
      I18n.t :no_results_title_text
    end

    def row_class
      ::Enumerations::RowCell
    end

    def headers
      [
        ['name', caption: Enumeration.human_attribute_name(:name)],
        ['is_default', caption: Enumeration.human_attribute_name(:is_default)],
        ['is_default', caption: Enumeration.human_attribute_name(:active)],
        ['sort', caption: I18n.t(:label_sort)]
      ].tap do |default|
        if with_colors
          default.insert 3, ['color', caption: Enumeration.human_attribute_name(:color)]
        end
      end
    end
  end
end
