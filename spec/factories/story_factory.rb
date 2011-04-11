Factory.define(:story) do |s|
  s.association :priority, :factory => :priority
  s.sequence(:subject) { |n| "story{n}" }
  s.description "story story story"
  s.association :tracker, :factory => :tracker_feature
  s.association :author, :factory => :user
end