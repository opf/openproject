# frozen_string_literal: true

require 'spec_helper'

module Grape
  module DSL
    module ConfigurationSpec
      class Dummy
        include Grape::DSL::Configuration
      end
    end
    describe Configuration do
      subject { Class.new(ConfigurationSpec::Dummy) }
    end
  end
end
