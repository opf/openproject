### From http://svn.geekdaily.org/public/rails/plugins/generally_useful/tasks/coverage_via_rcov.rake

namespace :test do
  namespace :scm do
    namespace :setup do
      desc "Creates directory for test repositories"
      task :create_dir do
        FileUtils.mkdir_p Rails.root + '/tmp/test'
      end
      
      supported_scms = [:subversion, :cvs, :bazaar, :mercurial, :git, :darcs, :filesystem]
      
      desc "Creates a test subversion repository"
      task :subversion => :create_dir do
        repo_path = "tmp/test/subversion_repository"
        system "svnadmin create #{repo_path}"
        system "gunzip < test/fixtures/repositories/subversion_repository.dump.gz | svnadmin load #{repo_path}"
      end
      
      (supported_scms - [:subversion]).each do |scm|
        desc "Creates a test #{scm} repository"
        task scm => :create_dir do
          system "gunzip < test/fixtures/repositories/#{scm}_repository.tar.gz | tar -xv -C tmp/test"
        end
      end
      
      desc "Creates all test repositories"
      task :all => supported_scms
    end
  end
end

### Inspired by http://blog.labratz.net/articles/2006/12/2/a-rake-task-for-rcov
begin
  require 'rcov/rcovtask'

  rcov_options = "--rails --aggregate test/coverage.data --exclude '/gems/'"

  namespace :test do 
    desc "Aggregate code coverage for all tests"
    Rcov::RcovTask.new('coverage') do |t|
      t.libs << 'test'
      t.test_files = FileList['test/{unit,integration,functional}/*_test.rb']
      t.verbose = true
      t.rcov_opts << rcov_options
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
        t.rcov_opts << rcov_options
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
  # rcov not available
end
