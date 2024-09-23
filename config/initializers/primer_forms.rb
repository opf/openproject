# frozen_string_literal: true

Rails.application.config.to_prepare do
  Primer::Forms::Dsl::FormObject.include(Primer::OpenProject::Forms::Dsl::InputMethods)
  Primer::Forms::Dsl::InputGroup.include(Primer::OpenProject::Forms::Dsl::InputMethods)
end
