# frozen_string_literal: true

require 'grape/router/route'
require 'grape/util/cache'

module Grape
  class Router
    attr_reader :map, :compiled

    class NormalizePathCache < Grape::Util::Cache
      def initialize
        @cache = Hash.new do |h, path|
          normalized_path = +"/#{path}"
          normalized_path.squeeze!('/')
          normalized_path.sub!(%r{/+\Z}, '')
          normalized_path = '/' if normalized_path.empty?
          h[path] = -normalized_path
        end
      end
    end

    def self.normalize_path(path)
      NormalizePathCache[path]
    end

    def self.supported_methods
      @supported_methods ||= Grape::Http::Headers::SUPPORTED_METHODS + ['*']
    end

    def initialize
      @neutral_map = []
      @neutral_regexes = []
      @map = Hash.new { |hash, key| hash[key] = [] }
      @optimized_map = Hash.new { |hash, key| hash[key] = // }
    end

    def compile!
      return if compiled
      @union = Regexp.union(@neutral_regexes)
      @neutral_regexes = nil
      self.class.supported_methods.each do |method|
        routes = map[method]
        @optimized_map[method] = routes.map.with_index do |route, index|
          route.index = index
          Regexp.new("(?<_#{index}>#{route.pattern.to_regexp})")
        end
        @optimized_map[method] = Regexp.union(@optimized_map[method])
      end
      @compiled = true
    end

    def append(route)
      map[route.request_method] << route
    end

    def associate_routes(pattern, **options)
      @neutral_regexes << Regexp.new("(?<_#{@neutral_map.length}>)#{pattern.to_regexp}")
      @neutral_map << Grape::Router::AttributeTranslator.new(options.merge(pattern: pattern, index: @neutral_map.length))
    end

    def call(env)
      with_optimization do
        response, route = identity(env)
        response || rotation(env, route)
      end
    end

    def recognize_path(input)
      any = with_optimization { greedy_match?(input) }
      return if any == default_response
      any.endpoint
    end

    private

    def identity(env)
      route = nil
      response = transaction(env) do |input, method|
        route = match?(input, method)
        process_route(route, env) if route
      end
      [response, route]
    end

    def rotation(env, exact_route = nil)
      response = nil
      input, method = *extract_input_and_method(env)
      map[method].each do |route|
        next if exact_route == route
        next unless route.match?(input)
        response = process_route(route, env)
        break unless cascade?(response)
      end
      response
    end

    def transaction(env)
      input, method = *extract_input_and_method(env)
      response = yield(input, method)

      return response if response && !(cascade = cascade?(response))
      neighbor = greedy_match?(input)

      # If neighbor exists and request method is OPTIONS,
      # return response by using #call_with_allow_headers.
      return call_with_allow_headers(
        env,
        neighbor.allow_header,
        neighbor.endpoint
      ) if neighbor && method == Grape::Http::Headers::OPTIONS && !cascade

      route = match?(input, '*')
      return neighbor.endpoint.call(env) if neighbor && cascade && route

      if route
        response = process_route(route, env)
        return response if response && !(cascade = cascade?(response))
      end

      !cascade && neighbor ? call_with_allow_headers(env, neighbor.allow_header, neighbor.endpoint) : nil
    end

    def process_route(route, env)
      input, = *extract_input_and_method(env)
      routing_args = env[Grape::Env::GRAPE_ROUTING_ARGS]
      env[Grape::Env::GRAPE_ROUTING_ARGS] = make_routing_args(routing_args, route, input)
      route.exec(env)
    end

    def make_routing_args(default_args, route, input)
      args = default_args || { route_info: route }
      args.merge(route.params(input))
    end

    def extract_input_and_method(env)
      input = string_for(env[Grape::Http::Headers::PATH_INFO])
      method = env[Grape::Http::Headers::REQUEST_METHOD]
      [input, method]
    end

    def with_optimization
      compile! unless compiled
      yield || default_response
    end

    def default_response
      [404, { Grape::Http::Headers::X_CASCADE => 'pass' }, ['404 Not Found']]
    end

    def match?(input, method)
      current_regexp = @optimized_map[method]
      return unless current_regexp.match(input)
      last_match = Regexp.last_match
      @map[method].detect { |route| last_match["_#{route.index}"] }
    end

    def greedy_match?(input)
      return unless @union.match(input)
      last_match = Regexp.last_match
      @neutral_map.detect { |route| last_match["_#{route.index}"] }
    end

    def call_with_allow_headers(env, methods, endpoint)
      env[Grape::Env::GRAPE_ALLOWED_METHODS] = methods.join(', ').freeze
      endpoint.call(env)
    end

    def cascade?(response)
      response && response[1][Grape::Http::Headers::X_CASCADE] == 'pass'
    end

    def string_for(input)
      self.class.normalize_path(input)
    end
  end
end
