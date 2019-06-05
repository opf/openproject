require_dependency 'statuses/row_cell'

module Statuses
  class TableCell < ::TableCell

    def initial_sort
      %i[id asc]
    end

    def sortable?
      false
    end

    def columns
      headers.map(&:first)
    end

    def inline_create_link
      link_to new_status_path,
              aria: { label: t(:label_work_package_status_new) },
              class: 'wp-inline-create--add-link',
              title: t(:label_work_package_status_new) do
        op_icon('icon icon-add')
      end
    end

    def empty_row_message
      I18n.t :no_results_title_text
    end

    def row_class
      ::Statuses::RowCell
    end

    def headers
      [
        [:name, caption: Status.human_attribute_name(:name)],
        [:color, caption: Status.human_attribute_name(:color)],
        [:is_default, caption: Status.human_attribute_name(:is_default)],
        [:is_closed, caption: Status.human_attribute_name(:is_closed)],
        [:is_readonly, caption: Status.human_attribute_name(:is_readonly)],
        [:sort, caption: I18n.t(:label_sort)]
      ].tap do |default|
        if WorkPackage.use_status_for_done_ratio?
          default.insert 2, [:done_ratio, caption: WorkPackage.human_attribute_name(:done_ratio)]
        end
      end
    end
  end
end
