#clear the doc:app task et al
Rake::Task["doc:app"].clear
Rake::Task["doc/app"].clear
Rake::Task["doc/app/index.html"].clear

namespace :doc do
  desc "Generate documentation for the application. Set custom template with TEMPLATE=/path/to/rdoc/template.rb or title with TITLE=\"Custom Title\""
  Rake::RDocTask.new("app") { |rdoc|
    rdoc.rdoc_dir = 'doc/app'
    rdoc.template = ENV['template'] if ENV['template']
    rdoc.title    = ENV['title'] || "ChiliProject"
    rdoc.options << '--line-numbers' << '--inline-source'
    rdoc.options << '--charset' << 'utf-8'
    rdoc.rdoc_files.include('app/**/*.rb')
    rdoc.rdoc_files.include('lib/**/*.rb')
    rdoc.rdoc_files.include('README.rdoc')
    rdoc.rdoc_files.include('doc/*.rdoc')
    rdoc.main = 'README.rdoc'
  }
end
