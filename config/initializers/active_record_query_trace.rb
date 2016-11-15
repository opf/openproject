if Rails.env.development?
  ActiveRecordQueryTrace.enabled = true
  ActiveRecordQueryTrace.lines = 1
  ActiveRecordQueryTrace.colorize = 'light purple'
end
