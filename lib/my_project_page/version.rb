module MyProjectPage
  module Version
    def to_s
      [major, minor, patch].join('.')
    end

    def full
      to_s
    end

    def major
      1
    end

    def minor
      0
    end

    def patch
      1
    end

    extend self
  end
end

