# Method for controller tests where you want to do everything in the context of the
# provided user without the hassle of locking in the user and cleaning up User.current
# afterwards
#
# Example usage:
#
#   as_logged_in_user admin do
#     post :create, { :name => "foo" }
#   end

def as_logged_in_user(user, &block)
  @controller.stub!(:user_setup).and_return(user)
  User.stub!(:current).and_return(user)

  yield
end
