# frozen_string_literal: true

# MetaTags gem namespace.
module MetaTags
  # Returns MetaTags gem configuration.
  #
  def self.config
    @config ||= Configuration.new
  end

  # Configures MetaTags gem.
  #
  # @yield [Configuration] configuration object.
  # @example
  #
  #   MetaTags.configure do |config|
  #     # config.title_limit = 100
  #   end
  def self.configure
    yield config
  end
end

require 'meta_tags/version'

require 'meta_tags/configuration'
require 'meta_tags/controller_helper'
require 'meta_tags/meta_tags_collection'
require 'meta_tags/renderer'
require 'meta_tags/tag'
require 'meta_tags/content_tag'
require 'meta_tags/text_normalizer'
require 'meta_tags/view_helper'

require 'meta_tags/railtie.rb' if defined?(Rails)
