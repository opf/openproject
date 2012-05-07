Factory.define :cost_entry do |ce|
  ce.association :cost_type, :factory => :cost_type
end
