if ENV['COVERAGE']
  # make sure to load most of the files, otherwise they are ignored in the coverage report
  Dir[File.join(File.dirname(__FILE__), '../app/**/*.rb')].sort.each { |f| require f }
  Dir[File.join(File.dirname(__FILE__), '../lib/**/*.rb')]
end
