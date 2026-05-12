# frozen_string_literal: true

class Automations::Actions::CustomField::ForUser < Automations::Actions::CustomField
  include Automations::Actions::Strategies::UserCustomField
end
