require 'roar/decorator'
require 'roar/representer/json'
require 'roar/representer/json/hal'

module Users
  class UserRepresenter < Roar::Decorator
    include Roar::Representer::JSON
    include Roar::Representer::Feature::Hypermedia
    include Roar::Representer::JSON::HAL

    property :id
    property :login
    property :firstname
    property :lastname
    property :mail
    property :admin
    property :status
    property :last_login_on
    property :language
    property :created_on
    property :updated_on
    property :type
    property :identity_url
    property :mail_notification

    link :self do
      "/users/#{represented.id}"
    end
  end
end
