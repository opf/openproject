require 'active_support'
require 'active_support/lazy_load_hooks'
require 'active_model'
require "active_model/serializers/version"

ActiveSupport.on_load(:active_record) do
  require "active_record/serializers/xml_serializer"
end

module ActiveModel
  module Serializers
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :Xml
    end
  end

  def self.eager_load!
    super
    ActiveModel::Serializers.eager_load!
  end
end
