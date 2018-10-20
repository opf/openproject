module CustomActions
  class TableCell < ::TableCell
    columns :name,
            :description,
            :sort

    def initial_sort
      %i[id asc]
    end

    def sortable?
      false
    end

    def inline_create_link
      link_to new_custom_action_path,
              aria: { label: t('custom_actions.new') },
              class: 'wp-inline-create--add-link',
              title: t('custom_actions.new') do
        op_icon('icon icon-add')
      end
    end

    def empty_row_message
      I18n.t :no_results_title_text
    end

    def headers
      [
        ['name', caption: CustomAction.human_attribute_name(:name)],
        ['description', caption: CustomAction.human_attribute_name(:description)],
        ['sort', caption: I18n.t(:label_sort)]
      ]
    end
  end
end
