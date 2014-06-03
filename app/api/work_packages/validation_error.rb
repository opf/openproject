class ValidationError < Grape::Exceptions::Base
  attr_reader :code, :title, :description, :headers

  def initialize(obj, args = { })
    @obj = obj
    @code = args[:code] || 422
    @title = args[:title] || 'validation_error'
    @description = args[:description] || 'Validation failed.'
    @headers = { 'Content-Type' => 'application/hal+json' }.merge(args[:headers] || { })
  end

  def errors
    @obj.errors.messages.map{ |m| { key: m[0], messages: m[1] }}
  end

  def to_json
    { title: @title, description: @description, errors: errors }.to_json
  end
end
