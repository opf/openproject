require 'rubygems'
require 'rake/testtask'

require 'rbconfig'
require 'fileutils'

spec = eval File.read('ruby-ole.gemspec')

task :default => [:test]

Rake::TestTask.new do |t|
	t.test_files = FileList["test/test_*.rb"]
	t.warning = true
	t.verbose = true
end

begin
	Rake::TestTask.new(:coverage) do |t|
		t.test_files = FileList["test/test_*.rb"]
		t.warning = true
		t.verbose = true
		t.ruby_opts = ['-rsimplecov -e "SimpleCov.start; load(ARGV.shift)"']
	end
rescue LoadError
	# SimpleCov not available
end

begin
	require 'rdoc/task'
	RDoc::Task.new do |t|
		t.rdoc_dir = 'doc'
		t.rdoc_files.include 'lib/**/*.rb'
		t.rdoc_files.include 'README.rdoc', 'ChangeLog'
		t.title    = "#{PKG_NAME} documentation"
		t.options += %w[--line-numbers --inline-source --tab-width 2]
		t.main	   = 'README.rdoc'
	end
rescue LoadError
	# RDoc not available or too old (<2.4.2)
end

begin
	require 'rubygems/package_task'
	Gem::PackageTask.new(spec) do |t|
		t.need_tar = true
		t.need_zip = false
		t.package_dir = 'build'
	end
rescue LoadError
	# RubyGems too old (<1.3.2)
end

desc 'Run various benchmarks'
task :benchmark do
	require 'benchmark'
	require 'tempfile'
	require 'ole/storage'

	# should probably add some read benchmarks too
	def write_benchmark opts={}
		files, size = opts[:files], opts[:size]
		block_size = opts[:block_size] || 100_000
		block = 0.chr * block_size
		blocks, remaining = size.divmod block_size
		remaining = 0.chr * remaining
		Tempfile.open 'ole_storage_benchmark' do |temp|
			Ole::Storage.open temp do |ole|
				files.times do |i|
					ole.file.open "file_#{i}", 'w' do |f|
						blocks.times { f.write block }
						f.write remaining
					end
				end
			end
		end
	end

	Benchmark.bm do |bm|
		bm.report 'write_1mb_1x5' do
			5.times { write_benchmark :files => 1, :size => 1_000_000 }
		end

		bm.report 'write_1mb_2x5' do
			5.times { write_benchmark :files => 1_000, :size => 1_000 }
		end
	end
end

