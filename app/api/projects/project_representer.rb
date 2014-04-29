require 'roar/decorator'
require 'roar/representer/json'
require 'roar/representer/json/hal'

module Projects
  class ProjectRepresenter < Roar::Decorator
    include Roar::Representer::JSON
    include Roar::Representer::Feature::Hypermedia
    include Roar::Representer::JSON::HAL

    property :id
    property :name
    property :description
    property :homepage
    property :is_public
    property :created_on
    property :updated_on
    property :identifier
    property :status
    property :summary

    link :self do
      "/project/#{represented.id}"
    end

    property :responsible, class: User, decorator: Users::UserRepresenter, embedded: true
  end
end
