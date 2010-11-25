namespace :db do
  desc "dump schema"
  task(:migrate_plugins) { Rake::Task["db:schema:dump"].invoke }
end