# Capistrano Recipes for managing delayed_job
#
# Add these callbacks to have the delayed_job process restart when the server
# is restarted:
#
#   after "deploy:stop",    "delayed_job:stop"
#   after "deploy:start",   "delayed_job:start"
#   after "deploy:restart", "delayed_job:restart"
#
# If you want to use command line options, for example to start multiple workers,
# define a Capistrano variable delayed_job_args:
#
#   set :delayed_job_args, "-n 2"
#
# If you've got delayed_job workers running on a servers, you can also specify
# which servers have delayed_job running and should be restarted after deploy.
#
#   set :delayed_job_server_role, :worker
#

Capistrano::Configuration.instance.load do
  namespace :delayed_job do
    def rails_env
      fetch(:rails_env, false) ? "RAILS_ENV=#{fetch(:rails_env)}" : ''
    end

    def args
      fetch(:delayed_job_args, '')
    end

    def roles
      fetch(:delayed_job_server_role, :app)
    end

    def delayed_job_command
      fetch(:delayed_job_command, 'script/delayed_job')
    end

    desc 'Stop the delayed_job process'
    task :stop, :roles => lambda { roles } do
      run "cd #{current_path} && #{rails_env} #{delayed_job_command} stop #{args}"
    end

    desc 'Start the delayed_job process'
    task :start, :roles => lambda { roles } do
      run "cd #{current_path} && #{rails_env} #{delayed_job_command} start #{args}"
    end

    desc 'Restart the delayed_job process'
    task :restart, :roles => lambda { roles } do
      run "cd #{current_path} && #{rails_env} #{delayed_job_command} restart #{args}"
    end
  end
end
