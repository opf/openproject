require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe GlobalRole do
  before {GlobalRole.create :name => "globalrole", :permissions => ["permissions"]} # for validate_uniqueness_of

  it {should have_many :principals}
  it {should have_many :principal_roles}
  it {should validate_presence_of :name}
  it {should validate_uniqueness_of :name}
  it {should ensure_length_of(:name).is_at_most(30)}

  describe "attributes" do
    before {@role = GlobalRole.new}

    subject {@role}

    it {should respond_to :name}
    it {should respond_to :permissions}
    it {should respond_to :position}
  end

  describe "class methods" do
    describe "WITH available global permissions defined" do
      before (:each) do
        @permission_options = [:perm1, :perm2, :perm3]
        Redmine::AccessControl.stub!(:global_permissions).and_return(@permission_options)
      end

      describe :setable_permissions do
        it {GlobalRole.setable_permissions.should eql @permission_options}
      end
    end
  end

  describe "instance methods" do
    before (:each) do
      @role = GlobalRole.new

      if costs_plugin_loaded?
        @perm = mock_model(Redmine::AccessControl::Permission)
        Redmine::AccessControl.stub!(:permission).and_return @perm
        @perm.stub!(:inherited_by).and_return([])
        @perm.stub!(:name).and_return(:perm)
        @perm.stub!(:inherits).and_return([])
      end
    end

    describe "WITH no attributes set" do
      before (:each) do
        @role = GlobalRole.new
      end

      describe :permissions do
        subject {@role.permissions}

        it {should be_an_instance_of(Array)}
        it {should have(0).items}
      end

      describe :permissions= do
        describe "WITH parameter" do
          before {@role.should_receive(:write_attribute).with(:permissions, [:perm1, :perm2])}

          it "should write permissions" do
            @role.permissions = [:perm1, :perm2]
          end

          it "should write permissions only once" do
            @role.permissions = [:perm1, :perm2, :perm2]
          end

          it "should write permissions as symbols" do
            @role.permissions = ["perm1", "perm2"]
          end

          it "should remove empty perms" do
            @role.permissions = [:perm1, :perm2, "", nil]
          end
        end

        describe "WITHOUT parameter" do
          before {@role.should_receive(:write_attribute).with(:permissions, nil)}

          it "should write permissions" do
            @role.permissions = nil
          end
        end
      end

      describe :has_permission? do
        it {@role.has_permission?(:perm).should be_false}
      end

      describe :allowed_to? do
        describe "WITH requested permission" do
          it {@role.allowed_to?(:perm1).should be_false}
        end
      end
    end

    describe "WITH set permissions" do
      before{ @role = GlobalRole.new :permissions => [:perm1, :perm2, :perm3]}

      describe :has_permission? do
        it {@role.has_permission?(:perm1).should be_true}
        it {@role.has_permission?("perm1").should be_true}
        it {@role.has_permission?(:perm5).should be_false}
      end

      describe :allowed_to? do
        describe "WITH requested permission" do
          it {@role.allowed_to?(:perm1).should be_true}
          it {@role.allowed_to?(:perm5).should be_false}
        end
      end
    end

    describe "WITH available global permissions defined" do
      before (:each) do
        @role = GlobalRole.new
        @permission_options = [:perm1, :perm2, :perm3]
        Redmine::AccessControl.stub!(:global_permissions).and_return(@permission_options)
      end

      describe :setable_permissions do
        it {@role.setable_permissions.should eql @permission_options}
      end
    end

    describe "WITH set name" do
      before{ @role = GlobalRole.new :name => "name"}

      describe :to_s do
        it {@role.to_s.should eql("name")}
      end
    end

    describe :destroy do
      before {@role = GlobalRole.create :name => "global"}

      it {@role.destroy}
    end

    describe :assignable do
      it {@role.assignable.should be_false}
    end

    describe :assignable= do
      it {lambda {@role.assignable = true}.should raise_error ArgumentError}
      it {lambda {@role.assignable = false}.should_not raise_error ArgumentError}
    end

    describe :assignable_to? do
      before(:each) do
        @role = Factory.build(:global_role)
        @user = Factory.build(:user)
      end
      it "always true global roles for now" do
        @role.assignable_to?(@user).should be_true
      end
    end
  end

end