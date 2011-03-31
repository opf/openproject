Factory.define(:impediment) do |t|
  t.association :tracker, :factory => :tracker_task
  t.subject "Impeding progress"
  t.description "Unable to print recipes"
  t.association :priority, :factory => :priority
  t.association :author, :factory => :user
end