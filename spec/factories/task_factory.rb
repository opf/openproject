Factory.define(:task, :parent => :issue, :class => Task) do |t|
  t.association :tracker, :factory => :tracker_task
end