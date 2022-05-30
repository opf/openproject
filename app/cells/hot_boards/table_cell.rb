module HotBoards
  class TableCell < ::TableCell
    columns :title

    def sortable?
      false
    end

    def headers
      [
        [:title, { caption: 'Title' }]
      ]
    end

    def inline_create_link
      link_to new_hot_board_path,
              class: 'wp-inline-create--add-link' do
        op_icon('icon icon-add')
      end
    end
  end
end
