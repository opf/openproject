module CodeRay
module Encoders
  
  load :token_class_filter
  
  class CommentFilter < TokenClassFilter
    
    register_for :comment_filter
    
    DEFAULT_OPTIONS = TokenClassFilter::DEFAULT_OPTIONS.merge \
      :exclude => [:comment]
    
  end
  
end
end
