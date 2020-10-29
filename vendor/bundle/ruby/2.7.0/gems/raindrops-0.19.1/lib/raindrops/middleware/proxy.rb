# -*- encoding: binary -*-
# :stopdoc:
# This class is used by Raindrops::Middleware to proxy application
# response bodies.  There should be no need to use it directly.
class Raindrops::Middleware::Proxy
  def initialize(body, stats)
    @body, @stats = body, stats
  end

  # yield to the Rack server here for writing
  def each
    @body.each { |x| yield x }
  end

  # the Rack server should call this after #each (usually ensure-d)
  def close
    @stats.decr_writing
    @body.close if @body.respond_to?(:close)
  end

  # Some Rack servers can optimize response processing if it responds
  # to +to_path+ via the sendfile(2) system call, we proxy +to_path+
  # to the underlying body if possible.
  def to_path
    @body.to_path
  end

  # Rack servers use +respond_to?+ to check for the presence of +close+
  # and +to_path+ methods.
  def respond_to?(m, include_all = false)
    m = m.to_sym
    :close == m || @body.respond_to?(m, include_all)
  end

  # Avoid breaking users of non-standard extensions (e.g. #body)
  # Rack::BodyProxy does the same.
  def method_missing(*args, &block)
    @body.__send__(*args, &block)
  end
end
