source "https://rubygems.org"
gemspec
gem "minitest-line"

{ "dry-types" => ENV['DRY_TYPES'], "activerecord" => ENV['ACTIVERECORD']}.each do |gem_name, dependency|
  next if dependency.nil?
  gem gem_name, dependency
end

gem "sqlite3", ENV.fetch('ACTIVERECORD', '5.2').to_f >= 6 ? '~> 1.4' : '~> 1.3.0'
