module Webhooks
  class Event < ApplicationRecord
    belongs_to :webhook
    validates_associated :webhook
    validates_presence_of :name
  end
end
