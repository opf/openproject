Rate.class_eval do
  generator_for :valid_from, :method => :next_valid_from
  generator_for :rate, 10

  def self.next_valid_from
    1.year.ago + Rate.count
  end
end
