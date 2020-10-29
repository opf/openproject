require 'messagebird/base'

module MessageBird
  class GroupReference < MessageBird::Base
    attr_accessor :href, :totalCount
  end
end
