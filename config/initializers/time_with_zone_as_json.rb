class ActiveSupport::TimeWithZone
  def as_json(options = {})
    %(#{time.strftime("%m/%d/%Y/ %H:%M %p")})
  end
end