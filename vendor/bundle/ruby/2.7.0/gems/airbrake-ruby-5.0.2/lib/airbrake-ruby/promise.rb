module Airbrake
  # Represents a simplified promise object (similar to promises found in
  # JavaScript), which allows chaining callbacks that are executed when the
  # promise is either resolved or rejected.
  #
  # @see https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Global_Objects/Promise
  # @see https://github.com/ruby-concurrency/concurrent-ruby/blob/master/lib/concurrent/promise.rb
  # @since v1.7.0
  class Promise
    def initialize
      @on_resolved = []
      @on_rejected = []
      @value = {}
      @mutex = Mutex.new
    end

    # Attaches a callback to be executed when the promise is resolved.
    #
    # @example
    #   Airbrake::Promise.new.then { |response| puts response }
    #   #=> {"id"=>"00054415-8201-e9c6-65d6-fc4d231d2871",
    #   #    "url"=>"http://localhost/locate/00054415-8201-e9c6-65d6-fc4d231d2871"}
    #
    # @yield [response]
    # @yieldparam response [Hash<String,String>] Contains the `id` & `url` keys
    # @return [self]
    def then(&block)
      @mutex.synchronize do
        if @value.key?('ok')
          yield(@value['ok'])
          return self
        end

        @on_resolved << block
      end

      self
    end

    # Attaches a callback to be executed when the promise is rejected.
    #
    # @example
    #   Airbrake::Promise.new.rescue { |error| raise error }
    #
    # @yield [error] The error message from the API
    # @yieldparam error [String]
    # @return [self]
    def rescue(&block)
      @mutex.synchronize do
        if @value.key?('error')
          yield(@value['error'])
          return self
        end

        @on_rejected << block
      end

      self
    end

    # @example
    #   Airbrake::Promise.new.resolve('id' => '123')
    #
    # @param reason [Object]
    # @return [self]
    def resolve(reason = 'resolved')
      @mutex.synchronize do
        @value['ok'] = reason
        @on_resolved.each { |callback| callback.call(reason) }
      end

      self
    end

    # @example
    #   Airbrake::Promise.new.reject('Something went wrong')
    #
    # @param reason [String]
    # @return [self]
    def reject(reason = 'rejected')
      @mutex.synchronize do
        @value['error'] = reason
        @on_rejected.each { |callback| callback.call(reason) }
      end

      self
    end

    # @return [Boolean]
    def rejected?
      @value.key?('error')
    end

    # @return [Boolean]
    def resolved?
      @value.key?('ok')
    end

    # @return [Hash<String,String>] either successful response containing the
    #   +id+ key or unsuccessful response containing the +error+ key
    # @note This is a non-blocking call!
    # @todo Get rid of this method and use an accessor. The resolved guard is
    #   needed for compatibility but it shouldn't exist in the future
    def value
      return @value['ok'] if resolved?

      @value
    end
  end
end
