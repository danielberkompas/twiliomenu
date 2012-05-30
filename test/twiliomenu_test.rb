require 'minitest/spec'
require 'minitest/autorun'

def verb_must_be_present(object, verb)
  object.verbs.last[:name].must_equal     verb[:name]
  object.verbs.last[:text].must_equal     verb[:text]
  object.verbs.last[:options].must_equal  verb[:options]
end

describe Call do
  before do
    @call = Call.new
  end

  describe "Class Modifications" do
    
    describe "Attributes Accessible" do
      it "should all be present" do
        @call.must_respond_to :verbs
        @call.must_respond_to :nest
        @call.must_respond_to :options
        @call.must_respond_to :twilio    
      end

      it "should all be of the right types" do
        @call.verbs.must_be_kind_of Array
        @call.nest.wont_be_nil
        @call.options.must_be_kind_of Array
        @call.twilio.must_be_kind_of Hash
      end
    end

    describe "Added Class Methods" do
      it "should have an acts_as_menu action" do
        Call.must_respond_to :acts_as_menu
      end

      it "should have a menu action" do
        Call.must_respond_to :menu
      end
    end

    describe "Class Method Functionality" do
      # Add some tests here
    end

    describe "Added Instance Methods" do
      it "should have a set_defaults action" do
        @call.must_respond_to :set_defaults     
      end

      it "should be able to add a verb to the instance method" do
        verb = {
          name: "Say",
          text: "Hello there!",
          options: {
            voice: "man"
          }
        }

        @call.send :add_verb, verb[:name], verb[:text], verb[:options]
        verb_must_be_present @call, verb
      end

    end
  end
end


# require 'test_helper'

# class TwiliomenuTest < ActiveSupport::TestCase
#   test "truth" do
#     assert_kind_of Module, Twiliomenu
#   end
# end
