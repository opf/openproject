# Keeps the #persisted? property synced with the model's.
module Disposable::Twin::Persisted
  def self.included(includer)
    includer.send(:property, :persisted?, writeable: false)
  end

  def save!(*)
    super.tap do
      send "persisted?=", model.persisted?
    end
  end

  def created?
    # when the persisted field got flipped, this means creation!
    changed?(:persisted?)
  end

  # DISCUSS: i did not add #updated? on purpose. while #created's semantic is clear, #updated is confusing.
  # does it include change, etc. i leave this up to the user until we have a clear definition.
end