class CreateDefaultWorkingDaysSettingEntry < ActiveRecord::Migration[7.0]
  def change
    Setting.where(name: "working_days").first_or_create!(value: Setting.working_days)
  end
end
