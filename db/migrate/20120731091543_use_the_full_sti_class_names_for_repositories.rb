class UseTheFullStiClassNamesForRepositories < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.execute("UPDATE `repositories` SET `type` = CONCAT('Repository::',`type`) WHERE `type` NOT LIKE 'Repository::%'")
  end

  def self.down
    # noop, full class name should also work with older versions of active record
  end
end
