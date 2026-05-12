# frozen_string_literal: true

class Automations::Actions::CustomField::ForText < Automations::Actions::CustomField
  include Automations::Actions::Strategies::Text
  include Automations::Actions::Strategies::CustomField
end
