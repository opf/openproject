# Borrows from http://gist.github.com/bf4/5320847
# without addressable requirement
# Accepts options[:allowed_protocols]
class UrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    url = parse(value)

    if url.nil?
      record.errors.add(attribute, :invalid_url)
    elsif !allowed_protocols.include?(url.scheme)
      record.errors.add(attribute, :invalid_url_scheme, allowed_schemes: allowed_protocols.join(', '))
    end
  end

  def parse(value)
    url = URI.parse(value)
  rescue => e
    nil
  end
  def allowed_protocols
    options.fetch(:allowed_protocols, %w(http https))
  end
end
