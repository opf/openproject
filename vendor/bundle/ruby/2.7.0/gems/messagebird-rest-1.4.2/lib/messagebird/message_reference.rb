require 'messagebird/base'

module MessageBird
  class MessageReference < MessageBird::Base
    attr_accessor :href, :totalCount
  end
end
