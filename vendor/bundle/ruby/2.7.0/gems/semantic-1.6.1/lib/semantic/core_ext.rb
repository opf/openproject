class String
  def to_version
    Semantic::Version.new self
  end

  def is_version?
    (match Semantic::Version::SemVerRegexp) ? true : false
  end
end
