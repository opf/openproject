Factory.define(:task) do |t|
  t.association :tracker, :factory => :tracker_task
  t.subject "Printing Recipes"
  t.description "Unable to print recipes"
  t.association :priority, :factory => :priority
  t.association :author, :factory => :user
end