class UpdateProgressCalculation < ActiveRecord::Migration[7.1]
  # See https://community.openproject.org/wp/40749 for migration details
  def up
    current_mode = progress_calculation_mode
    if current_mode == "disabled"
      set_progress_calculation_mode_to_work_based
      previous_mode = "disabled"
      current_mode = "field"
    end

    perform_method = Rails.env.development? ? :perform_now : :perform_later
    WorkPackages::Progress::MigrateValuesJob.public_send(perform_method, current_mode:, previous_mode:)
  end

  def progress_calculation_mode
    value_from_db = ActiveRecord::Base.connection
      .execute("SELECT value FROM settings WHERE name = 'work_package_done_ratio'")
      .first
      &.fetch("value", nil)
    value_from_db || "field"
  end

  def set_progress_calculation_mode_to_work_based
    ActiveRecord::Base.connection.execute("UPDATE settings SET value = 'field' WHERE name = 'work_package_done_ratio'")
  end
end
