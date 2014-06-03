class UnwritablePropertyError < Grape::Exceptions::Base
  attr_reader :code, :title, :description, :headers

  def initialize(property, args = { })
    @property = property
    @code = args[:code] || 422
    @title = args[:title] || 'unwriteable_property_error'
    @description = args[:description] || 'You tried to write read-only property.'
    @headers = { 'Content-Type' => 'application/hal+json' }.merge(args[:headers] || { })
  end

  def errors
    [{ key: @property, messages: ['is read-only'] }]
  end

  def to_json
    { title: @title, description: @description, errors: errors }.to_json
  end
end
