require 'roar/representer/json'
require 'roar/decorator'
require 'roar/representer/json/hal'

module WorkPackages
  class UserRepresenter < Roar::Decorator
    include Roar::Representer::JSON
    include Roar::Representer::JSON::HAL
    include Roar::Representer::Feature::Hypermedia
    include Rails.application.routes.url_helpers

    property :login
    property :firstname
    property :lastname
    property :mail
    property :_type, exec_context: :decorator

    link :self do
      { href: "http://localhost:3000/api/v3/users/#{represented.id}", title: "User." }
    end

    def _type
      "User"
    end
  end
end
