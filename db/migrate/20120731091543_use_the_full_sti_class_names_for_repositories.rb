class UseTheFullStiClassNamesForRepositories < ActiveRecord::Migration
  def self.up
    if ActiveRecord::Base.connection.adapter_name =~ /sqlite/i
      concatenation = "('Repository::' || type)"
    else
      concatenation = "CONCAT('Repository::', type)"
    end

    Repository.update_all "type = #{concatenation}", "type NOT LIKE 'Repository::%'"
  end

  def self.down
    # noop, full class name should also work with older versions of active record
  end
end
