require "rubygems"
require "hoe"
require "concourse"

Hoe.plugin :git
Hoe.plugin :gemspec
Hoe.plugin :bundler
Hoe.plugin :debugging
Hoe.plugin :markdown

Hoe.spec "loofah" do
  developer "Mike Dalessio", "mike.dalessio@gmail.com"
  developer "Bryan Helmkamp", "bryan@brynary.com"

  self.license "MIT"
  self.urls = {
    "home" => "https://github.com/flavorjones/loofah",
    "bugs" => "https://github.com/flavorjones/loofah/issues",
    "doco" => "https://www.rubydoc.info/gems/loofah/",
    "clog" => "https://github.com/flavorjones/loofah/blob/master/CHANGELOG.md",
    "code" => "https://github.com/flavorjones/loofah",
  }

  extra_deps << ["nokogiri", ">=1.5.9"]
  extra_deps << ["crass", "~> 1.0.2"]

  extra_dev_deps << ["rake", "~> 12.3"]
  extra_dev_deps << ["minitest", "~>2.2"]
  extra_dev_deps << ["rr", "~>1.2.0"]
  extra_dev_deps << ["json", "~> 2.3.0"]
  extra_dev_deps << ["hoe-gemspec", "~> 1.0"]
  extra_dev_deps << ["hoe-debugging", "~> 2.0"]
  extra_dev_deps << ["hoe-bundler", "~> 1.5"]
  extra_dev_deps << ["hoe-git", "~> 1.6"]
  extra_dev_deps << ["hoe-markdown", "~> 1.2"]
  extra_dev_deps << ["concourse", ">=0.26.0"]
  extra_dev_deps << ["rubocop", ">=0.76.0"]
end

task :gemspec do
  system %q(rake debug_gem | grep -v "^\(in " > loofah.gemspec)
end

task :redocs => :fix_css
task :docs => :fix_css
task :fix_css do
  better_css = <<-EOT
    .method-description pre {
      margin                    : 1em 0 ;
    }

    .method-description ul {
      padding                   : .5em 0 .5em 2em ;
    }

    .method-description p {
      margin-top                : .5em ;
    }

    #main ul, div#documentation ul {
      list-style-type           : disc ! IMPORTANT ;
      list-style-position       : inside ! IMPORTANT ;
    }

    h2 + ul {
      margin-top                : 1em;
    }
  EOT
  puts "* fixing css"
  File.open("doc/rdoc.css", "a") { |f| f.write better_css }
end

desc "generate and upload docs to rubyforge"
task :doc_upload_to_rubyforge => :docs do
  Dir.chdir "doc" do
    system "rsync -avz --delete * rubyforge.org:/var/www/gforge-projects/loofah/loofah"
  end
end

desc "generate safelists from W3C specifications"
task :generate_safelists do
  load "tasks/generate-safelists"
end

task :rubocop => [:rubocop_security, :rubocop_frozen_string_literals]
task :rubocop_security do
  sh "rubocop lib --only Security"
end
task :rubocop_frozen_string_literals do
  sh "rubocop lib --auto-correct --only Style/FrozenStringLiteralComment"
end
Rake::Task[:test].prerequisites << :rubocop

Concourse.new("loofah", fly_target: "ci") do |c|
  c.add_pipeline "loofah", "loofah.yml"
  c.add_pipeline "loofah-pr", "loofah-pr.yml"
end
