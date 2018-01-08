module Webhooks
  class Event < ActiveRecord::Base
    belongs_to :webhook
    validates_associated :webhook
    validates_presence_of :name
  end
end