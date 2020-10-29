source 'https://rubygems.org'

gemspec

group :development, :test do
  gem 'bundler'
  gem 'rake'
  gem 'rspec', '~> 3.5'
end

group :test do
  gem 'simplecov', require: false, platform: :mri
end

group :tools do
  gem 'ossy', git: 'https://github.com/solnic/ossy.git', branch: 'master', platform: :mri
end
