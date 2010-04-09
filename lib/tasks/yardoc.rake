begin
  require 'yard'

  YARD::Rake::YardocTask.new do |t|
    t.files = ['lib/**/*.rb', 'app/**/*.rb', 'vendor/plugins/**/*.rb']
  end

rescue LoadError
  # yard not installed (gem install yard)
  # http://yardoc.org
end
