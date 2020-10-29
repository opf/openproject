class ActiveRecord::Tasks::NullDBDatabaseTasks
  def initialize(configuration)
    @configuration = configuration
  end

  def create(master_established = false)
    # NO-OP
  end

  def drop
    # NO-OP
  end

  def purge
    # NO-OP
  end

  def structure_dump(filename, extra_flags)
    # NO-OP
  end

  def structure_load(filename, extra_flags)
    # NO-OP
  end

  def clear_active_connections!
    # NO-OP
  end
end
