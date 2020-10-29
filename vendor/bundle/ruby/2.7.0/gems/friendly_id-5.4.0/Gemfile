source 'https://rubygems.org'

gemspec

gem 'rake'

group :development, :test do
  platforms :ruby do
    gem 'byebug'
    gem 'pry'
  end

  platforms :jruby do
    gem 'activerecord-jdbcsqlite3-adapter', '>= 1.3.0.beta2'
    gem 'kramdown'
  end

  platforms :ruby, :rbx do
    gem 'sqlite3'
    gem 'redcarpet'
  end

  platforms :rbx do
    gem 'rubysl', '~> 2.0'
    gem 'rubinius-developer_tools'
  end
end
