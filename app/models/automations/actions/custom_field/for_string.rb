# frozen_string_literal: true

class Automations::Actions::CustomField::ForString < Automations::Actions::CustomField
  include Automations::Actions::Strategies::String
  include Automations::Actions::Strategies::CustomField
end
