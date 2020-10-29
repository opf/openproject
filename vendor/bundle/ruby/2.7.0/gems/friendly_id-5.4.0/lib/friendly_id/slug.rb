module FriendlyId
  # A FriendlyId slug stored in an external table.
  #
  # @see FriendlyId::History
  class Slug < ActiveRecord::Base
    belongs_to :sluggable, :polymorphic => true

    def sluggable
      sluggable_type.constantize.unscoped { super }
    end

    def to_param
      slug
    end

  end
end
