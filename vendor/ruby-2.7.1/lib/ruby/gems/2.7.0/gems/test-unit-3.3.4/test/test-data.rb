require "testunit-test-util"

class TestData < Test::Unit::TestCase
  class Calc
    def initialize
    end

    def plus(augend, addend)
      augend + addend
    end
  end

  class TestCalc < Test::Unit::TestCase
    @@testing = false

    class << self
      def testing=(testing)
        @@testing = testing
      end
    end

    def valid?
      @@testing
    end

    def setup
      @calc = Calc.new
    end

    class TestDataSet < TestCalc
      data("positive positive" => {:expected => 4, :augend => 3, :addend => 1},
           "positive negative" => {:expected => -1, :augend => 1, :addend => -2})
      def test_plus(data)
        assert_equal(data[:expected],
                     @calc.plus(data[:augend], data[:addend]))
      end
    end

    class TestNData < TestCalc
      data("positive positive", {:expected => 4, :augend => 3, :addend => 1})
      data("positive negative", {:expected => -1, :augend => 1, :addend => -2})
      def test_plus(data)
        assert_equal(data[:expected],
                     @calc.plus(data[:augend], data[:addend]))
      end
    end

    class TestDynamicDataSet < TestCalc
      DATA_PROC = lambda do
        data_set = {}
        data_set["positive positive"] = {
          :expected => 3,
          :augend => 1,
          :addend => 2
        }
        data_set["positive negative"] = {
          :expected => -1,
          :augend => 1,
          :addend => -2
        }
        data_set
      end

      data(&DATA_PROC)
      def test_plus(data)
        assert_equal(data[:expected],
                     @calc.plus(data[:augend], data[:addend]))
      end
    end

    class TestLoadDataSet < TestCalc
      extend TestUnitTestUtil
      load_data(fixture_file_path("plus.csv"))
      def test_plus(data)
        assert_equal(data["expected"],
                     @calc.plus(data["augend"], data["addend"]))
      end
    end

    class TestSuperclass < TestCalc
      data("positive positive" => {:expected => 4, :augend => 3, :addend => 1},
           "positive negative" => {:expected => -1, :augend => 1, :addend => -2})
      def test_plus(data)
        assert_equal(data[:expected],
                     @calc.plus(data[:augend], data[:addend]))
      end

      class TestNormalTestInSubclass < self
        def test_plus
          assert_equal(2, @calc.plus(1, 1))
        end
      end
    end

    class TestMethod < TestCalc
      def data_test_plus
        {
          "positive positive" => {:expected => 4, :augend => 3, :addend => 1},
          "positive negative" => {:expected => -1, :augend => 1, :addend => -2},
        }
      end

      def test_plus(data)
        assert_equal(data[:expected],
                     @calc.plus(data[:augend], data[:addend]))
      end
    end

    class TestPatterns < TestCalc
      data(:x, [-1, 1, 0])
      data(:y, [-100, 100])
      data(:z, ["a", "b", "c"])
      def test_use_data(data)
      end
    end

    class TestPatternsKeep < TestCalc
      data(:x, [-1, 1, 0], keep: true)
      data(:y, [-100, 100])
      data(:z, ["a", "b", "c"], keep: true)
      def test_use_data(data)
      end

      def test_use_data_keep(data)
      end
    end

    class TestPatternsGroup < TestCalc
      data(:a, [-1, 1, 0], group: 1)
      data(:b, [:a, :b], group: 1)
      data(:x, [2, 9], group: :z)
      data(:y, ["a", "b", "c"], group: :z)
      def test_use_data(data)
      end
    end
  end

  def setup
    TestCalc.testing = true
  end

  def teardown
    TestCalc.testing = false
  end

  def test_data_no_arguments_without_block
    assert_raise(ArgumentError) do
      self.class.data
    end
  end

  data("data set",
       {
         :test_case => TestCalc::TestDataSet,
         :data_sets => [
           {
             "positive positive" => {
               :expected => 4,
               :augend => 3,
               :addend => 1,
             },
             "positive negative" => {
               :expected => -1,
               :augend => 1,
               :addend => -2,
             },
           },
         ],
       })
  data("n-data",
       {
         :test_case => TestCalc::TestNData,
         :data_sets => [
           {
             "positive positive" => {
               :expected => 4,
               :augend => 3,
               :addend => 1,
             },
           },
           {
             "positive negative" => {
               :expected => -1,
               :augend => 1,
               :addend => -2,
             },
           },
         ],
       })
  data("dynamic-data-set",
       {
         :test_case => TestCalc::TestDynamicDataSet,
         :data_sets => [TestCalc::TestDynamicDataSet::DATA_PROC],
       })
  data("load-data-set",
       {
         :test_case => TestCalc::TestLoadDataSet,
         :data_sets => [
           {
             "positive positive" => {
               "expected" => 4,
               "augend" => 3,
               "addend" => 1,
             },
           },
           {
             "positive negative" => {
               "expected" => -1,
               "augend" => 1,
               "addend" => -2,
             },
           },
         ],
       })
  def test_data(data)
    test_plus = data[:test_case].new("test_plus")
    data_sets = Test::Unit::DataSets.new
    data[:data_sets].each do |data_set|
      data_sets.add(data_set)
    end
    assert_equal(data_sets, test_plus[:data])
  end

  def test_data_patterns
    test = TestCalc::TestPatterns.new("test_use_data")
    data_sets = Test::Unit::DataSets.new
    data_sets << [:x, [-1, 1, 0]]
    data_sets << [:y, [-100, 100]]
    data_sets << [:z, ["a", "b", "c"]]
    assert_equal(data_sets, test[:data])
  end

  def test_data_patterns_keep
    test = TestCalc::TestPatternsKeep.new("test_use_data_keep")
    data_sets = Test::Unit::DataSets.new
    data_sets.add([:x, [-1, 1, 0]], {keep: true})
    data_sets.add([:z, ["a", "b", "c"]], {keep: true})
    assert_equal(data_sets, test[:data])
  end

  data("data set"         => TestCalc::TestDataSet,
       "n-data"           => TestCalc::TestNData,
       "dynamic-data-set" => TestCalc::TestDynamicDataSet,
       "load-data-set"    => TestCalc::TestLoadDataSet)
  def test_suite(test_case)
    suite = test_case.suite
    assert_equal(["test_plus[positive negative](#{test_case.name})",
                  "test_plus[positive positive](#{test_case.name})"],
                 suite.tests.collect {|test| test.name}.sort)
  end

  def test_suite_patterns
    test_case = TestCalc::TestPatterns
    suite = test_case.suite
    assert_equal([
                   "test_use_data[x: -1, y: -100, z: \"a\"](#{test_case.name})",
                   "test_use_data[x: -1, y: -100, z: \"b\"](#{test_case.name})",
                   "test_use_data[x: -1, y: -100, z: \"c\"](#{test_case.name})",
                   "test_use_data[x: -1, y: 100, z: \"a\"](#{test_case.name})",
                   "test_use_data[x: -1, y: 100, z: \"b\"](#{test_case.name})",
                   "test_use_data[x: -1, y: 100, z: \"c\"](#{test_case.name})",
                   "test_use_data[x: 0, y: -100, z: \"a\"](#{test_case.name})",
                   "test_use_data[x: 0, y: -100, z: \"b\"](#{test_case.name})",
                   "test_use_data[x: 0, y: -100, z: \"c\"](#{test_case.name})",
                   "test_use_data[x: 0, y: 100, z: \"a\"](#{test_case.name})",
                   "test_use_data[x: 0, y: 100, z: \"b\"](#{test_case.name})",
                   "test_use_data[x: 0, y: 100, z: \"c\"](#{test_case.name})",
                   "test_use_data[x: 1, y: -100, z: \"a\"](#{test_case.name})",
                   "test_use_data[x: 1, y: -100, z: \"b\"](#{test_case.name})",
                   "test_use_data[x: 1, y: -100, z: \"c\"](#{test_case.name})",
                   "test_use_data[x: 1, y: 100, z: \"a\"](#{test_case.name})",
                   "test_use_data[x: 1, y: 100, z: \"b\"](#{test_case.name})",
                   "test_use_data[x: 1, y: 100, z: \"c\"](#{test_case.name})",
                 ],
                 suite.tests.collect {|test| test.name}.sort)
  end

  def test_suite_patterns_group
    test_case = TestCalc::TestPatternsGroup
    suite = test_case.suite
    assert_equal([
                   "test_use_data[group: 1, a: -1, b: :a](#{test_case.name})",
                   "test_use_data[group: 1, a: -1, b: :b](#{test_case.name})",
                   "test_use_data[group: 1, a: 0, b: :a](#{test_case.name})",
                   "test_use_data[group: 1, a: 0, b: :b](#{test_case.name})",
                   "test_use_data[group: 1, a: 1, b: :a](#{test_case.name})",
                   "test_use_data[group: 1, a: 1, b: :b](#{test_case.name})",
                   "test_use_data[group: :z, x: 2, y: \"a\"](#{test_case.name})",
                   "test_use_data[group: :z, x: 2, y: \"b\"](#{test_case.name})",
                   "test_use_data[group: :z, x: 2, y: \"c\"](#{test_case.name})",
                   "test_use_data[group: :z, x: 9, y: \"a\"](#{test_case.name})",
                   "test_use_data[group: :z, x: 9, y: \"b\"](#{test_case.name})",
                   "test_use_data[group: :z, x: 9, y: \"c\"](#{test_case.name})",
                 ],
                 suite.tests.collect {|test| test.name}.sort)
  end

  data("data set"         => TestCalc::TestDataSet,
       "n-data"           => TestCalc::TestNData,
       "dynamic-data-set" => TestCalc::TestDynamicDataSet,
       "load-data-set"    => TestCalc::TestLoadDataSet,
       "superclass"       => TestCalc::TestSuperclass,
       "method"           => TestCalc::TestMethod)
  def test_run(test_case)
    result = _run_test(test_case)
    assert_equal("2 tests, 2 assertions, 0 failures, 0 errors, 0 pendings, " \
                 "0 omissions, 0 notifications", result.to_s)
  end

  def test_run_normal_test_in_subclass
    result = _run_test(TestCalc::TestSuperclass::TestNormalTestInSubclass)
    assert_equal("1 tests, 1 assertions, 0 failures, 0 errors, 0 pendings, " \
                 "0 omissions, 0 notifications", result.to_s)
  end

  data("data set"         => TestCalc::TestDataSet,
       "n-data"           => TestCalc::TestNData,
       "dynamic-data-set" => TestCalc::TestDynamicDataSet,
       "load-data-set"    => TestCalc::TestLoadDataSet)
  def test_equal(test_case)
    suite = test_case.suite
    positive_positive_test = suite.tests.find do |test|
      test.data_label == "positive positive"
    end
    suite.tests.delete(positive_positive_test)
    assert_equal(["test_plus[positive negative](#{test_case.name})"],
                 suite.tests.collect {|test| test.name}.sort)
  end

  data("true"    => {:expected => true,    :target => "true"},
       "false"   => {:expected => false,   :target => "false"},
       "integer" => {:expected => 1,       :target => "1"},
       "float"   => {:expected => 1.5,     :target => "1.5"},
       "string"  => {:expected => "hello", :target => "hello"})
  def test_normalize_value(data)
    loader = Test::Unit::Data::ClassMethods::Loader.new(self)
    assert_equal(data[:expected], loader.__send__(:normalize_value, data[:target]))
  end

  def _run_test(test_case)
    result = Test::Unit::TestResult.new
    test = test_case.suite
    yield(test) if block_given?
    test.run(result) {}
    result
  end

  class TestLoadData < Test::Unit::TestCase
    include TestUnitTestUtil
    def test_invalid_csv_file_name
      garbage = "X"
      file_name = "data.csv#{garbage}"
      assert_raise(ArgumentError, "unsupported file format: <#{file_name}>") do
        self.class.load_data(file_name)
      end
    end

    class TestFileFormat < self
      def setup
        self.class.current_attribute(:data).clear
      end

      class TestHeader < self
        data("csv" => "header.csv",
             "tsv" => "header.tsv")
        def test_normal(file_name)
          self.class.load_data(fixture_file_path(file_name))
          data_sets = Test::Unit::DataSets.new
          data_sets << {
            "empty string" => {
              "expected" => true,
              "target"   => ""
            }
          }
          data_sets << {
            "plain string" => {
              "expected" => false,
              "target"   => "hello"
            }
          }
          assert_equal(data_sets,
                       self.class.current_attribute(:data)[:value])
        end

        data("csv" => "header-label.csv",
             "tsv" => "header-label.tsv")
        def test_label(file_name)
          self.class.load_data(fixture_file_path(file_name))
          data_sets = Test::Unit::DataSets.new
          data_sets << {
            "upper case" => {
              "expected" => "HELLO",
              "label"    => "HELLO"
            }
          }
          data_sets << {
            "lower case" => {
              "expected" => "Hello",
              "label"    => "hello"
            }
          }
          assert_equal(data_sets,
                       self.class.current_attribute(:data)[:value])
        end
      end

      data("csv" => "no-header.csv",
           "tsv" => "no-header.tsv")
      def test_without_header(file_name)
        self.class.load_data(fixture_file_path(file_name))
        data_sets = Test::Unit::DataSets.new
        data_sets << {"empty string" => [true, ""]}
        data_sets << {"plain string" => [false, "hello"]}
        assert_equal(data_sets,
                     self.class.current_attribute(:data)[:value])
      end
    end
  end
end
