# frozen_string_literal: true

module BoardsHelper
  BoardTypeAttributes = Struct.new(:radio_button_value, :title, :description, :image_path)

  def board_types
    [
      build_board_type_attributes('basic', 'lists'),
      build_board_type_attributes('status', 'status'),
      build_board_type_attributes('assignee', 'assignees'),
      build_board_type_attributes('version', 'version'),
      build_board_type_attributes('subproject', 'subproject'),
      build_board_type_attributes('subtasks', 'parent-child')
    ]
  end

  def build_board_type_attributes(type_name, image_name)
    BoardTypeAttributes.new(type_name,
                            I18n.t("boards.board_type_attributes.#{type_name}"),
                            I18n.t("boards.board_type_descriptions.#{type_name}"),
                            "assets/images/board_creation_modal/#{image_name}.svg")
  end
end
