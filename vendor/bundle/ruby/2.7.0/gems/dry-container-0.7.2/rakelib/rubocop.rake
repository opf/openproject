begin
  require 'rubocop/rake_task'

  Rake::Task[:default].enhance [:rubocop]

  RuboCop::RakeTask.new do |task|
    task.options << '--display-cop-names'
  end

  namespace :rubocop do
    desc 'Generate a configuration file acting as a TODO list.'
    task :auto_gen_config do
      exec 'bundle exec rubocop --auto-gen-config'
    end
  end

rescue LoadError
end
