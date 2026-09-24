# frozen_string_literal: true

module WorkPackages
  class TrashActionDialogComponent < ApplicationComponent
    include OpTurbo::Streamable

    attr_reader :work_packages, :action

    def initialize(work_packages:, action:, back_url: nil)
      super()
      @work_packages = work_packages
      @action = action
      @back_url = back_url
    end

    def dialog_id = "wp-trash-#{action}-dialog"

    def title = I18n.t("work_packages.trash.#{action}_dialog.title")

    def heading = I18n.t("work_packages.trash.#{action}_dialog.heading", count: work_packages.size)

    def description = I18n.t("work_packages.trash.#{action}_dialog.description", count: work_packages.size)

    def form_action
      action == :restore ? helpers.restore_work_packages_bulk_path : helpers.purge_work_packages_bulk_path
    end

    def form_method = action == :restore ? :post : :delete

    def button_label = I18n.t("work_packages.trash.#{action}_dialog.button")

    def button_scheme = action == :restore ? :primary : :danger

    def ids = work_packages.map(&:id)

    def back_url = @back_url
  end
end
