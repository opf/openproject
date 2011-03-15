#Seed the DB
Before do
  Fixtures.reset_cache
  fixtures_folder = File.join(RAILS_ROOT, 'test', 'fixtures')
  fixtures = Dir[File.join(fixtures_folder, '*.yml')].map {|f| File.basename(f, '.yml') }
  # Users are created using factory girl in redmine_cucumber
  fixtures -= ['users']
  Fixtures.create_fixtures(fixtures_folder, fixtures)
end