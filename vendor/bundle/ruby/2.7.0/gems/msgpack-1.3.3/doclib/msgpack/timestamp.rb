module MessagePack
  # A utility class for MessagePack timestamp type
  class Timestamp
    #
    # The timestamp extension type defined in the MessagePack spec.
    #
    # See https://github.com/msgpack/msgpack/blob/master/spec.md#timestamp-extension-type for details.
    #
    TYPE = -1

    # @return [Integer] Second part of the timestamp.
    attr_reader :sec

    # @return [Integer] Nanosecond part of the timestamp.
    attr_reader :nsec

    # @param [Integer] sec
    # @param [Integer] nsec
    def initialize(sec, nsec)
    end

    # @example An unpacker implementation for the Time class
    #   lambda do |payload|
    #     tv = MessagePack::Timestamp.from_msgpack_ext(payload)
    #     Time.at(tv.sec, tv.nsec, :nanosecond)
    #   end
    #
    # @param [String] data
    # @return [MessagePack::Timestamp]
    def self.from_msgpack_ext(data)
    end

    # @example A packer implementation for the Time class
    #   unpacker = lambda do |time|
    #     MessagePack::Timestamp.to_msgpack_ext(time.tv_sec, time.tv_nsec)
    #   end
    #
    # @param [Integer] sec
    # @param [Integer] nsec
    # @return [String]
    def self.to_msgpack_ext(sec, nsec)
    end
  end
end
