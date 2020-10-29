# frozen_string_literal: true

module Grape
  module Env
    API_VERSION = 'api.version'
    API_ENDPOINT = 'api.endpoint'
    API_REQUEST_INPUT = 'api.request.input'
    API_REQUEST_BODY = 'api.request.body'
    API_TYPE = 'api.type'
    API_SUBTYPE = 'api.subtype'
    API_VENDOR = 'api.vendor'
    API_FORMAT = 'api.format'

    RACK_INPUT = 'rack.input'
    RACK_REQUEST_QUERY_HASH = 'rack.request.query_hash'
    RACK_REQUEST_FORM_HASH = 'rack.request.form_hash'
    RACK_REQUEST_FORM_INPUT = 'rack.request.form_input'

    GRAPE_REQUEST = 'grape.request'
    GRAPE_REQUEST_HEADERS = 'grape.request.headers'
    GRAPE_REQUEST_PARAMS = 'grape.request.params'
    GRAPE_ROUTING_ARGS = 'grape.routing_args'
    GRAPE_ALLOWED_METHODS = 'grape.allowed_methods'
  end
end
