class Timestamp
  
  def initialize(arg = Timestamp.now.to_s)
    if arg.kind_of? String
      @timestamp_iso8601_string = arg
    elsif arg.respond_to? :iso8601
      @timestamp_iso8601_string = arg.iso8601
    else
      raise Timestamp::Exception, "Argument type not supported. Please provide a String or anything that responds to :iso8601, e.g. a Time."
    end
  end
  
  def self.parse(iso8601_string)
    if iso8601_string.start_with? "P" # ISO8601 "Period"
      ActiveSupport::Duration.parse(iso8601_string)
    else
      Time.parse(iso8601_string)
    end
    Timestamp.new(iso8601_string)
  end
  
  def self.now
    self.new(ActiveSupport::Duration.build(0).iso8601)
  end
  
  def relative?
    to_s.first == "P" # ISO8601 "Period"
  end
  
  def to_s
    iso8601
  end
  
  def to_str
    to_s
  end
  
  def iso8601
    @timestamp_iso8601_string.to_s
  end
  
  def inspect
    "#<Timestamp \"#{to_s}\">"
  end
  
  def to_time
    if relative?
      Time.zone.now - to_duration * (to_duration.to_i.positive? ? 1 : -1)
    else
      Time.parse(self)
    end
  end
  
  def to_duration
    if relative?
      ActiveSupport::Duration.parse(self)
    else
      raise Timestamp::Exception, "This timestamp is absolute and cannot be represented as ActiveSupport::Duration."
    end
  end
  
  def as_json
    to_s
  end
  
  def to_json
    to_s
  end
  
  def ==(other_timestamp)
    self.iso8601 == other_timestamp.iso8601
  end
  
  class Exception < StandardError; end
end