### From http://svn.geekdaily.org/public/rails/plugins/generally_useful/tasks/coverage_via_rcov.rake

### Inspired by http://blog.labratz.net/articles/2006/12/2/a-rake-task-for-rcov
begin
  require 'rcov/rcovtask'

  namespace :test do 
    desc "Aggregate code coverage for all tests"
    Rcov::RcovTask.new('coverage') do |t|
      t.libs << 'test'
      t.test_files = FileList['test/{unit,integration,functional}/*_test.rb']
      t.verbose = true
      t.rcov_opts << '--rails --aggregate test/coverage.data'
    end

    namespace :coverage do
      desc "Delete coverage test data"
      task :clean do
        rm_f "test/coverage.data"
        rm_rf "test/coverage"
      end

      desc "Aggregate code coverage for all tests with HTML output"
      Rcov::RcovTask.new('html') do |t|
        t.libs << 'test'
        t.test_files = FileList['test/{unit,integration,functional}/*_test.rb']
        t.output_dir = "test/coverage"
        t.verbose = true
        t.rcov_opts << '--rails --aggregate test/coverage.data'
      end
    
      desc "Open the HTML coverage report"
      task :show_results do
        system "open test/coverage/index.html"
      end

      task :full => "test:coverage:clean"
      task :full => "test:coverage:html"
      task :full => "test:coverage:show_results"
    end
  end
rescue LoadError
  puts 'Rcov is not available. Proceeding without...'
end
