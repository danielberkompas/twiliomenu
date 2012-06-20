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

      it "should have a working dial verb" do
        number = "555-555-555"
        options = {}

        verb = {
          name:     "Dial",
          text:     number,
          options:  options
        }

        @call.send :dial, number, options
        verb_must_be_present @call, verb
      end

      it "should have a working redirect verb" do
        verb = {
          name:     "Redirect",
          text:     "/hello/there",
          options:  {}
        }

        @call.send :redirect, verb[:text], verb[:options]
        verb_must_be_present @call, verb
      end

      it "#dial_multiple should allow nesting of other verbs" do
        @call.go_to_menu :dial_multiple
        @call.verbs.last[:nested].size.must_be :>, 0
      end

      describe "#prompt" do
        it "should be able to add digits to the options array" do
          digits      = 10
          text_to_say = "string"
          options     = { menu: :second_menu }

          @call.send :prompt, digits, text_to_say, options
          @call.options.last.must_equal [digits, options]
        end

        it "should be able to add regexes to the options array" do
          regex       = /50/
          text_to_say = "string"
          options     = { menu: :second_menu }

          @call.send :prompt, regex, text_to_say, options
          @call.options.last.must_equal [regex, options]
        end

        it "should be able to add strings to the options array" do
          string      = "*"
          text_to_say = "string"
          options     = { menu: :third_menu }

          @call.send :prompt, string, text_to_say, options
          @call.options.last.must_equal [string, options]
        end
      end

      describe "#process_options" do
        it "should be able to process regexes" do
          @call.current_menu.must_be :!=, :second_menu

          # Where it matches
          @call.options = [[/50/, {menu: :second_menu}]]
          @call.send :process_options, "50"

          @call.current_menu.must_equal :second_menu

          # Where it doesn't match
          @call.options = [[/50/, {menu: :third_menu}]]
          @call.send :process_options, "6523"

          @call.current_menu.must_be :!=, :third_menu
        end

        it "should be able to process strings" do
          @call.current_menu.must_be :!=, :second_menu

          # Where it matches
          @call.options = [["*", {menu: :second_menu}]]
          @call.send :process_options, "*"

          @call.current_menu.must_equal :second_menu

          # Where it doesn't match
          @call.options = [["*", {menu: :third_menu}]]
          @call.send :process_options, "6523"

          @call.current_menu.must_be :!=, :third_menu          
        end
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
