rule /^redmine:backlogs_plugin/ do |t|
  task_name = t.name.split(':backlogs_plugin:').last
  notice = "NOTICE: redmine:backlogs_plugin:#{task_name} is DEPRECATED. Use redmine:backlogs:#{task_name} instead."
  puts "*".ljust(notice.length, "*")
  puts notice
  puts "*".ljust(notice.length, "*")
  # exec "rake redmine:backlogs:#{task_name}"
  Rake::Task["redmine:backlogs:#{task_name}"].invoke
end