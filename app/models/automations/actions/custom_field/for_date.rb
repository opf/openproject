# frozen_string_literal: true

class Automations::Actions::CustomField::ForDate < Automations::Actions::CustomField
  include Automations::Actions::Strategies::CustomField
  include Automations::Actions::Strategies::Date
end
