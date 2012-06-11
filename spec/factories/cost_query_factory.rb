Factory.define(:cost_query) do |cq|
  cq.association :user, :factory => :user
  cq.association :project, :factory => :project
  cq.sequence(:name) { |n| "Cost Query #{n}" }
end

Factory.define(:private_cost_query, :parent => :cost_query) do |cq|
  cq.is_public false
end

Factory.define(:public_cost_query, :parent => :cost_query) do |cq|
  cq.is_public true
end
