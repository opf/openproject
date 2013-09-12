def without_timestamping
  if block_given?
    ActiveRecord::Base.record_timestamps = false
    begin
      yield
    ensure
      ActiveRecord::Base.record_timestamps = true 
    end
  end
end
