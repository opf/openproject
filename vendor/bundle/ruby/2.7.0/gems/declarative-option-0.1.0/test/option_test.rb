require "test_helper"
require "declarative/option"

class OptionTest < Minitest::Spec
  def Option(*args)
    Declarative::Option(*args)
  end

  # proc
  it { Option( ->(*args) { "proc! #{args.inspect}" } ).(1,2).must_equal "proc! [1, 2]" }
  it { Option( lambda { "proc!" } ).().must_equal "proc!" }

  # proc with instance_exec
  it { Option( ->(*args) { "#{self.class} #{args.inspect}" } ).(Object, 1, 2).must_equal "OptionTest [Object, 1, 2]" }
  it { Option( ->(*args) { "#{self} #{args.inspect}" }, instance_exec: true ).(Object, 1, 2).must_equal "Object [1, 2]" }

  # static
  it { Option(true).().must_equal true }
  it { Option(nil).().must_equal nil }
  it { Option(false).().must_equal false }
  # args are ignored.
  it { Option(true).(1,2,3).must_equal true }

  # instance method
  class Hello
    def hello(*args); "Hello! #{args.inspect}" end
  end
  it { Option(:hello).(Hello.new).must_equal "Hello! []" }
  it { Option(:hello).(Hello.new, 1, 2).must_equal "Hello! [1, 2]" }

  #---
  # Callable
  class Callio
    include Declarative::Callable
    def call(); "callable!" end
  end

  it { Option(Callio.new).().must_equal "callable!" }

  #---
  #- :callable overrides the marking class
  class Callme
    def call(*args); "callme! #{args}" end
  end
  it { Option(Callme.new, callable: Callme).().must_equal "callme! []" }

  # { callable: Object } will do
  # 1. proc?
  # 2. method?
  # 3. everything else is treated as callable.
  describe "callable: Object" do
    let (:options) { { callable: Object } }

    it { Option(Callme.new,                    options).(1).must_equal "callme! [1]" }
    # proc is detected before callable.
    it { Option(->(*args) { "proc! #{args}" }, options).(1).must_equal "proc! [1]" }
    # :method is detected before callable.
    it { Option(:hello,                        options).(Hello.new, 1).must_equal "Hello! [1]" }
  end

  #---
  #- override #callable?
  class MyCallableOption < Declarative::Option
    def callable?(*); true end
  end

  it { MyCallableOption.new.(Callme.new).().must_equal "callme! []" }
  # proc is detected before callable.
  it { MyCallableOption.new.(->(*args) { "proc! #{args.inspect}" }).(1).must_equal "proc! [1]" }
  # :method is detected before callable.
  it { MyCallableOption.new.(:hello).(Hello.new, 1).must_equal "Hello! [1]" }
end
