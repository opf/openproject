# -*- encoding: binary -*-

# This is a wrapper around Raindrops objects much like the core Ruby
# \Struct can be seen as a wrapper around the core \Array class.
# It's usage is similar to the core \Struct class, except its fields
# may only be used to house unsigned long integers.
#
#   class Foo < Raindrops::Struct.new(:readers, :writers)
#   end
#
#   foo = Foo.new 0, 0
#
#   foo.incr_writers    -> 1
#   foo.incr_readers    -> 1
#
class Raindrops::Struct

  # returns a new class derived from Raindrops::Struct and supporting
  # the given +members+ as fields, just like \Struct.new in core Ruby.
  def self.new(*members)
    members = members.map { |x| x.to_sym }.freeze
    str = <<EOS
def initialize(*values)
  (MEMBERS.size >= values.size) or raise ArgumentError, "too many arguments"
  @raindrops = Raindrops.new(MEMBERS.size)
  values.each_with_index { |val,i| @raindrops[i] = values[i] }
end

def initialize_copy(src)
  @raindrops = src.instance_variable_get(:@raindrops).dup
end

def []=(index, value)
  @raindrops[index] = value
end

def [](index)
  @raindrops[index]
end

def to_hash
  ary = @raindrops.to_ary
  rv = {}
  MEMBERS.each_with_index { |member, i| rv[member] = ary[i] }
  rv
end
EOS

    members.each_with_index do |member, i|
      str << "def incr_#{member}; @raindrops.incr(#{i}); end; " \
             "def decr_#{member}; @raindrops.decr(#{i}); end; " \
             "def #{member}; @raindrops[#{i}]; end; " \
             "def #{member}=(val); @raindrops[#{i}] = val; end; "
    end

    klass = Class.new
    klass.const_set(:MEMBERS, members)
    klass.class_eval(str)
    klass
  end

end
