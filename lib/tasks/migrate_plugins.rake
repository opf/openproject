namespace :db do
  desc 'Migrates installed plugins.'
  task :migrate_plugins => :environment do
    if Rails.respond_to?('plugins')
      Rails.plugins.each do |plugin|
        next unless plugin.respond_to?('migrate')
        puts "Migrating #{plugin.name}..."
        plugin.migrate
      end
    else
      puts "Undefined method plugins for Rails!"
      puts "Make sure engines plugin is installed."
    end
  end
end
