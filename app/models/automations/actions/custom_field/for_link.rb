# frozen_string_literal: true

class Automations::Actions::CustomField::ForLink < Automations::Actions::CustomField
  include Automations::Actions::Strategies::Link
  include Automations::Actions::Strategies::CustomField
end
