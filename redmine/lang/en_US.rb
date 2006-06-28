Localization.define('en', 'English') do |l| 
  l.store '(date)', lambda { |t| t.strftime('%m/%d/%Y') }
  l.store '(time)', lambda { |t| t.strftime('%m/%d/%Y %I:%M%p') }
end 