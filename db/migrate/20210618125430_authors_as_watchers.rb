class AuthorsAsWatchers < ActiveRecord::Migration[6.1]
  def up
    WorkPackage
      .includes(:author,  :project)
      .find_each do |work_package|
      Watcher.create(user: work_package.author, watchable: work_package)
    end
  end

  # No down since we cannot distinguish between watchers that existed before
  # and the ones that where created by the migration.
end
