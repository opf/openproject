class UpdateProgressCalculation < ActiveRecord::Migration[7.1]
  # See https://community.openproject.org/wp/40749 for migration details
  def up
    if progress_calculation_mode == "disabled"
      set_progress_calculation_mode_to_work_based
      previous_mode = "disabled"
    end

    perform_method = Rails.env.production? ? :perform_later : :perform_now
    WorkPackages::UpdateProgressJob.public_send(perform_method, previous_mode:)
  end

  def progress_calculation_mode
    ActiveRecord::Base.connection
      .execute("SELECT value FROM settings WHERE name = 'work_package_done_ratio'")
      .first
      &.fetch("value", nil)
  end

  def set_progress_calculation_mode_to_work_based
    ActiveRecord::Base.connection.execute("UPDATE settings SET value = 'field' WHERE name = 'work_package_done_ratio'")
  end
end
