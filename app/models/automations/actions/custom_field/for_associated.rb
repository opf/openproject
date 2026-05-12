# frozen_string_literal: true

class Automations::Actions::CustomField::ForAssociated < Automations::Actions::CustomField
  include Automations::Actions::Strategies::AssociatedCustomField
end
