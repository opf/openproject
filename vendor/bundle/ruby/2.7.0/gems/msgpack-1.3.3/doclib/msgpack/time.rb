module MessagePack

  # MessagePack::Time provides packer and unpacker functions for a timestamp type.
  # @example Setup for DefaultFactory
  #   MessagePack::DefaultFactory.register_type(
  #     MessagePack::Timestamp::TYPE,
  #     Time,
  #     packer: MessagePack::Time::Packer,
  #     unpacker: MessagePack::Time::Unpacker
  #   )
  class Time
    # A packer function that packs a Time instance to a MessagePack timestamp.
    Packer = lambda { |payload|
      # ...
    }

    # An unpacker function that unpacks a MessagePack timestamp to a Time instance.
    Unpacker = lambda { |time|
      # ...
    }
  end
end
