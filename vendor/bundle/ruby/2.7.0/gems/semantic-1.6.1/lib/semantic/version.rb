# See: http://semver.org
module Semantic
  class Version
    include Comparable

    SemVerRegexp = /\A(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][a-zA-Z0-9-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][a-zA-Z0-9-]*))*))?(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?\Z/


    attr_accessor :major, :minor, :patch, :pre
    attr_reader :build

    def initialize version_str
      v = version_str.match(SemVerRegexp)

      raise ArgumentError.new("#{version_str} is not a valid SemVer Version (http://semver.org)") if v.nil?
      @major = v[1].to_i
      @minor = v[2].to_i
      @patch = v[3].to_i
      @pre = v[4]
      @build = v[5]
      @version = version_str
    end


    def build=(b)
      @build = (!b.nil? && b.empty?) ? nil : b
    end

    def identifiers(pre)
      array = pre.split(/[\.\-]/)
      array.each_with_index {|e,i| array[i] = Integer(e) if /\A\d+\z/.match(e)}
      return array
    end

    def compare_pre(prea, preb)
      if prea.nil? || preb.nil?
        return 0 if prea.nil? && preb.nil?
        return 1 if prea.nil?
        return -1 if preb.nil?
      end
      a = identifiers(prea)
      b = identifiers(preb)
      smallest = a.size < b.size ? a : b
      smallest.each_with_index do |e, i|
        c = a[i] <=> b[i]
        if c.nil?
          return a[i].is_a?(Integer) ? -1 : 1
        elsif c != 0
          return c
        end
      end
      return a.size <=> b.size
    end

    def to_a
      [@major, @minor, @patch, @pre, @build]
    end

    def to_s
      str = [@major, @minor, @patch].join '.'
      str << '-' << @pre unless @pre.nil?
      str << '+' << @build unless @build.nil?
      str
    end

    def to_h
      keys = [:major, :minor, :patch, :pre, :build]
      Hash[keys.zip(self.to_a)]
    end

    alias to_hash to_h
    alias to_array to_a
    alias to_string to_s

    def hash
      to_a.hash
    end

    def eql? other_version
      self.hash == other_version.hash
    end

    def <=> other_version
      other_version = Version.new(other_version) if other_version.is_a? String
      [:major, :minor, :patch].each do |part|
        c = (self.send(part) <=> other_version.send(part))
        if c != 0
          return c
        end
      end
      return compare_pre(self.pre, other_version.pre)
    end

    def satisfies? other_version
      return true if other_version.strip == '*'
      parts = other_version.split(/(\d(.+)?)/, 2)
      comparator, other_version_string = parts[0].strip, parts[1].strip

      begin
        Version.new other_version_string
        comparator.empty? && comparator = '=='
        satisfies_comparator? comparator, other_version_string
      rescue ArgumentError
        if ['<', '>', '<=', '>='].include?(comparator)
          satisfies_comparator? comparator, pad_version_string(other_version_string)
        elsif comparator == '~>'
          pessimistic_match? other_version_string
        else
          tilde_matches? other_version_string
        end
      end
    end

    def satisfied_by? versions
      raise ArgumentError.new("Versions #{versions} should be an array of versions") unless versions.is_a? Array
      versions.all? { |version| satisfies?(version) }
    end

    [:major, :minor, :patch].each do |term|
      define_method("#{term}!") { increment!(term) }
    end

    def increment!(term)
      term = term.to_sym
      new_version = clone
      new_value = send(term) + 1

      new_version.send("#{term}=", new_value)
      new_version.minor = 0 if term == :major
      new_version.patch = 0 if term == :major || term == :minor
      new_version.build = new_version.pre = nil

      new_version
    end

    private

    def pad_version_string version_string
      parts = version_string.split('.').reject {|x| x == '*'}
      while parts.length < 3
        parts << '0'
      end
      parts.join '.'
    end

    def tilde_matches? other_version_string
      this_parts = to_a.collect(&:to_s)
      other_parts = other_version_string.split('.').reject {|x| x == '*'}
      other_parts == this_parts[0..other_parts.length-1]
    end

    def pessimistic_match? other_version_string
      other_parts = other_version_string.split('.')
      unless other_parts.size == 2 || other_parts.size == 3
        raise ArgumentError.new("Version #{other_version_string} should not be applied with a pessimistic operator")
      end
      other_parts.pop
      other_parts << (other_parts.pop.to_i + 1).to_s
      satisfies_comparator?('>=', semverified(other_version_string)) && satisfies_comparator?('<', semverified(other_parts.join('.')))
    end

    def satisfies_comparator? comparator, other_version_string
      if comparator == '~'
        tilde_matches? other_version_string
      elsif comparator == '~>'
        pessimistic_match? other_version_string
      else
        self.send comparator, other_version_string
      end
    end

    def semverified version_string
      parts = version_string.split('.')
      raise ArgumentError.new("Version #{version_string} not supported by semverified") if parts.size > 3
      (3 - parts.size).times { parts << '0' }
      parts.join('.')
    end

  end
end
