FactoryBot.define do
  factory :type_scheme do
    sequence(:name) { |n| "Scheme #{n}" }
    active { true }
    is_default { false }
    transient { types { [create(:type)] } }
    after(:build) do |scheme, ev|
      ev.types.each_with_index do |t, i|
        scheme.items.build(type: t, position: i + 1, is_default: i.zero?)
      end
    end
  end
end
