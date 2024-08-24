class RemoveTotalsFromChildlessWorkPackages < ActiveRecord::Migration[7.1]
  def up
    perform_method = Rails.env.development? ? :perform_now : :perform_later
    WorkPackages::Progress::MigrateRemoveTotalsFromChildlessWorkPackagesJob.public_send(perform_method)
  end
end
