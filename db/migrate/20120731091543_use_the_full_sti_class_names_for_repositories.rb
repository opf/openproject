class UseTheFullStiClassNamesForRepositories < ActiveRecord::Migration
  def self.up
    concatenation = "('Repository::' || type)"

    # special concat for mysql
    if ChiliProject::Database.mysql?
      concatenation = "CONCAT('Repository::', type)"
    end

    Repository.update_all "type = #{concatenation}", "type NOT LIKE 'Repository::%'"
  end

  def self.down
    # noop, full class name should also work with older versions of active record
  end
end
