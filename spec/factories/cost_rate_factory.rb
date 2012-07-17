Factory.define :cost_rate do |r|
  r.association :cost_type, :factory => :cost_type
  r.valid_from Date.today
  r.rate 50.0
end
