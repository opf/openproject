# frozen_string_literal: true

module BoardsHelper
  BoardTypeAttributes = Struct.new(:radio_button_value,
                                   :title,
                                   :description,
                                   :image_path)

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

  def global_board_create_context?
    global_board_new_action? || global_board_create_action?
  end

  def global_board_new_action?
    request.path == new_work_package_board_path
  end

  def global_board_create_action?
    request.path == work_package_boards_path && @project.nil?
  end
end
