
RSpec.configure do |c|
  # If the filename is being changed change it in lib/tasks/parallel_testing.rake
  c.example_status_persistence_file_path = "tmp/rspec-examples.txt"
  c.run_all_when_everything_filtered = true
end
