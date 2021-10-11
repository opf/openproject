config = Rails.env.production? && Rails.application.config.database_configuration[Rails.env]
pool_size = config && [OpenProject::Configuration.web_max_threads + 1, config['pool'].to_i].max

# make sure we have enough connections in the pool for each thread and then some
if pool_size && pool_size > ActiveRecord::Base.connection_pool.size
  Rails.logger.debug { "Increasing database pool size to #{pool_size} to match max threads" }

  ActiveRecord::Base.establish_connection config.merge(pool: pool_size)
end
