# frozen_string_literal: true

class Automations::Actions::CustomField::ForBoolean < Automations::Actions::CustomField
  include Automations::Actions::Strategies::Boolean
  include Automations::Actions::Strategies::CustomField
end
