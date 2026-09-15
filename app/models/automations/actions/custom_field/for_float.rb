# frozen_string_literal: true

class Automations::Actions::CustomField::ForFloat < Automations::Actions::CustomField
  include Automations::Actions::Strategies::Float
  include Automations::Actions::Strategies::CustomField
end
