# frozen_string_literal: true

Rails.application.config.to_prepare do
  Primer::Forms::Dsl::FormObject.include(OpPrimer::Forms::Dsl::InputMethods)
end
