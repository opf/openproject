Factory.define(:impediment, :parent => :issue, :class => Impediment) do |t|
  t.association :tracker, :factory => :tracker_task
  t.subject "Impeding progress"
end