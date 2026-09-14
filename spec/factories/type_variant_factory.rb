# frozen_string_literal: true

FactoryBot.define do
  # A named variant of a type. Every type already owns a base variant, so this always builds
  # an additional, named one — use `type.default_variant` for the base configuration.
  factory :type_variant do
    type
    sequence(:variant_name) { |n| "Variant No. #{n}" }

    # A variant only the owning project can see or use.
    factory :project_owned_type_variant do
      project
    end
  end
end
