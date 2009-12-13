desc 'Removes watchers from what they can no longer view.'

namespace :redmine do
  namespace :watchers do
    task :prune => :environment do
      Watcher.prune
    end
  end
end
