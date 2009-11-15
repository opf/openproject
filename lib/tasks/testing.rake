### From http://svn.geekdaily.org/public/rails/plugins/generally_useful/tasks/coverage_via_rcov.rake

namespace :test do
  desc 'Measures test coverage'
  task :coverage do
    rm_f "coverage"
    rm_f "coverage.data"
    rcov = "rcov --rails --aggregate coverage.data --text-summary -Ilib --html"
    files = Dir.glob("test/**/*_test.rb").join(" ")
    system("#{rcov} #{files}")
    system("open coverage/index.html") if PLATFORM['darwin']
  end

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
