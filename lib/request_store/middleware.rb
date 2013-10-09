module RequestStore
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      RequestStore.clear!
      @app.call(env)
    end
  end

  def self.store
    Thread.current[:request_store] ||= {}
  end

  def self.clear!
    Thread.current[:request_store] = {}
  end
end