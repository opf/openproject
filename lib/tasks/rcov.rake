begin
  require 'cucumber/rake/task' #I have to add this
  
  namespace :redmine do
    namespace :backlogs do 
  
  
      desc "Generate RCov report for Redmine Backlogs"
      task :rcov => ["rcov:all"]
  
      namespace :rcov do
        Cucumber::Rake::Task.new(:cucumber) do |t|    
          t.cucumber_opts = " --no-color"
          t.rcov = true
          t.rcov_opts = %w{ --rails --text-report --include-file vendor\/plugins\/redmine_backlogs --exclude config\/,features\/.+\/,^app\/,^lib\/,osx\/objc,gems\/ }
          t.rcov_opts << %[-o "coverage"]
        end
        
        task :all do |t|
          rm "coverage.data" if File.exist?("coverage.data")
          Rake::Task["redmine:backlogs:rcov:cucumber"].invoke
        end
      end
    end
  end
rescue LoadError
  #pass
end
