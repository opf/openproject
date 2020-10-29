#! /usr/bin/ruby

$: << File.dirname(__FILE__) + '/../lib'

require 'test/unit'
require 'ole/support'

class TestSupport < Test::Unit::TestCase
	TEST_DIR = File.dirname __FILE__

	def test_file
		assert_equal 4096, open("#{TEST_DIR}/oleWithDirs.ole") { |f| f.size }
		# point is to have same interface as:
		assert_equal 4096, StringIO.open(open("#{TEST_DIR}/oleWithDirs.ole", 'rb', &:read)).size
	end

	def test_enumerable
		expect = {0 => [2, 4], 1 => [1, 3]}
		assert_equal expect, [1, 2, 3, 4].group_by { |i| i & 1 }
		assert_equal 10, [1, 2, 3, 4].sum
		assert_equal %w[1 2 3 4], [1, 2, 3, 4].map(&:to_s)
	end

	def test_logger
		io = StringIO.new
		log = Logger.new_with_callstack io
		log.warn 'test'
		expect = %r{^\[\d\d:\d\d:\d\d .*?test_support\.rb:\d+:test_logger\]\nWARN   test$}
		assert_match expect, io.string.chomp
	end

	def test_io
		str = 'a' * 5000 + 'b'
		src, dst = StringIO.new(str), StringIO.new
		IO.copy src, dst
		assert_equal str, dst.string
	end

	def test_symbol
		array = (1..10).to_a
		assert_equal 55, array.inject(&:+)
	end
end

class TestIOMode < Test::Unit::TestCase
	def mode s
		Ole::IOMode.new s
	end

	def test_parse
		assert_equal true,  mode('r+bbbbb').binary?
		assert_equal false, mode('r+').binary?

		assert_equal false, mode('r+').create?
		assert_equal false, mode('r').create?
		assert_equal true,  mode('wb').create?

		assert_equal true,  mode('w').truncate?
		assert_equal false, mode('r').truncate?
		assert_equal false, mode('r+').truncate?

		assert_equal true,  mode('r+').readable?
		assert_equal true,  mode('r+').writeable?
		assert_equal false, mode('r').writeable?
		assert_equal false, mode('w').readable?

		assert_equal true,  mode('a').append?
		assert_equal false, mode('w+').append?
	end

	def test_invalid
		assert_raises(ArgumentError) { mode 'rba' }
		assert_raises(ArgumentError) { mode '+r' }
	end
	
	def test_inspect
		assert_equal '#<Ole::IOMode rdonly>', mode('r').inspect
		assert_equal '#<Ole::IOMode rdwr|creat|trunc|binary>', mode('wb+').inspect
		assert_equal '#<Ole::IOMode wronly|creat|append>', mode('a').inspect
	end
end

class TestRecursivelyEnumerable < Test::Unit::TestCase
	class Container
		include RecursivelyEnumerable
	
		def initialize *children
			@children = children
		end
	
		def each_child(&block)
			@children.each(&block)
		end
	
		def inspect
			"#<Container>"
		end
	end
	
	def setup
		@root = Container.new(
			Container.new(1),
			Container.new(2,
				Container.new(
					Container.new(3)
				)
			),
			4,
			Container.new()
		)
	end

	def test_find
		i = 0
		found = @root.recursive.find do |obj|
			i += 1
			obj == 4
		end
		assert_equal found, 4
		assert_equal 9, i

		i = 0
		found = @root.recursive(:breadth_first).find do |obj|
			i += 1
			obj == 4
		end
		assert_equal found, 4
		assert_equal 4, i

		# this is to make sure we hit the breadth first child cache
		i = 0
		found = @root.recursive(:breadth_first).find do |obj|
			i += 1
			obj == 3
		end
		assert_equal found, 3
		assert_equal 10, i
	end

	def test_to_tree
		assert_equal <<-'end', @root.to_tree
- #<Container>
  |- #<Container>
  |  \- 1
  |- #<Container>
  |  |- 2
  |  \- #<Container>
  |     \- #<Container>
  |        \- 3
  |- 4
  \- #<Container>
		end
	end
end

