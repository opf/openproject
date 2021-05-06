FactoryBot.define do
  trait :skip_validations do
    to_create { |model| model.save!(validate: false) }
  end
end
