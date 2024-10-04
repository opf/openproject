# frozen_string_literal: true

class WorkPackages::StatusButtonComponent < ApplicationComponent
  include OpPrimer::ComponentHelpers

  def initialize(work_package:, user:, readonly: false, button_arguments: {}, menu_arguments: {})
    super

    @work_package = work_package
    @user = user
    @status = work_package.status
    @project = work_package.project

    @readonly = readonly
    @menu_arguments = menu_arguments
    @button_arguments = button_arguments.merge({ classes: "__hl_background_status_#{@status.id}" })

    @items = available_statusses
  end

  def button_title
    I18n.t("js.label_edit_status")
  end

  def disabled?
    !@user.allowed_in_project?(:edit_work_packages, @project)
  end

  def readonly?
    @status.is_readonly?
  end

  def button_arguments
    { title: button_title,
      disabled: disabled?,
      aria: {
        label: button_title
      } }.deep_merge(@button_arguments)
  end

  def available_statusses
    WorkPackages::UpdateContract.new(@work_package, @user)
                                .assignable_statuses
  end
end
