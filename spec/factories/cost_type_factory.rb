Factory.define :cost_type do |ct|
  ct.sequence(:name) { |n| "ct no. #{n}" }
  ct.unit "singular_unit"
  ct.unit_plural "plural_unit"
end

