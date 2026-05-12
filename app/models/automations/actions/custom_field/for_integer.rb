# frozen_string_literal: true

class Automations::Actions::CustomField::ForInteger < Automations::Actions::CustomField
  include Automations::Actions::Strategies::Integer
  include Automations::Actions::Strategies::CustomField
end
