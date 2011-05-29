
desc 'Fetch changesets from the repositories'

namespace :redmine do
  task :fetch_changesets => :environment do
    Repository.fetch_changesets
  end
end
