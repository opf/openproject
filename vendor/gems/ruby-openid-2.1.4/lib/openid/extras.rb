class String
  def starts_with?(other)
    head = self[0, other.length]
    head == other
  end

  def ends_with?(other)
    tail = self[-1 * other.length, other.length]
    tail == other
  end
end
