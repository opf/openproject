require 'roar/decorator'
require 'roar/representer/json'
require 'roar/representer/json/hal'

module Versions
  class VersionRepresenter < Roar::Decorator
    include Roar::Representer::JSON
    include Roar::Representer::Feature::Hypermedia
    include Roar::Representer::JSON::HAL

    property :id
    property :name
    property :description
    property :effective_date, getter: lambda { |args| effective_date.to_time.to_i }
    property :created_on, getter: lambda { |args| created_on.to_time.to_i }
    property :updated_on, getter: lambda { |args| updated_on.to_time.to_i }
    property :woki_page_title
    property :status

    link :self do
      "/versions/#{represented.id}"
    end
  end
end
