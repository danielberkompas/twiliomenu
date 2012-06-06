require 'twilio-rb'

module Twiliomenu
  module ActsAsMenu
    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods
      def acts_as_menu(options = {})
        instance_eval do
          attr_accessor :verbs, :nest, :menus, :options, :twilio
          alias_method :go_to_menu, :transition_to

          after_initialize :set_defaults

          define_method :set_defaults do
            self.current_menu = self.current_menu || options[:default] || :opening_menu
            self.verbs = []
            self.options = []
            self.twilio = {}
            self.send("menu_#{self.current_menu}")
          end
        end
      end

      def menu(name, &block)
        define_method "menu_#{name.to_s}" do |twilio = nil|
          self.instance_eval(&block)
        end
      end
    end

    # Instance Methods
    # The following are simple instance methods, not class methods.
    # They will be mixed in to the including class simply by the
    # #include method.

    # Renders TwiML for the object based on the current menu.
    def twiml
      prepare_current_menu!

      ::Twilio::TwiML.build do |r|
        for verb in self.verbs do
          recursive_build(r, verb)
        end
      end
    end
    
    # Recursively loops through the array of verbs and returns
    # a TwiML tag for each one.  It supports nesting, and loops
    # through the :nested verbs on each verb.
    # 
    # Theoretically, this allows for infinite nesting of verbs.
    def recursive_build(builder, verb)
      allows_nesting = ["Gather"]

      # Recursively run through all of the nested verbs in each block
      if allows_nesting.include?( verb[:name] )

        builder.__send__ verb[:name].to_sym, verb[:options] do |nb|        
          for nested_verb in verb[:nested] do
            recursive_build(nb, nested_verb) 
          end
        end

      # If this verb doesn't support nesting, just print it out
      else
        builder.__send__ verb[:name].to_sym, verb[:text], verb[:options]
      end
    end
    
    # Determines what menu to transition the object to based on
    # digits that the user entered.
    #
    # Also stores the current twilio params in an instance variable
    # so that the menus can run logic against those params.
    # 
    # The current params are also stored in the @twilio instance
    # variable on the model.  This allows you to do logic in your
    # menus based on what twilio is passing you.
    #
    # @param twilio (hash) - Hash of parameters passed to a 
    # controller action by twilio.  They should be passed directly
    # into the model like so: @object.process_twilio_response(params).
    def process_twilio_response(twilio = nil)
      @twilio = twilio
      prepare_current_menu!
      process_options(@twilio[:Digits]) if @twilio[:Digits]
    end

    # Transitions the object to another menu
    def transition_to(menu_name)
      self.update_attribute(:current_menu, menu_name)
      self.__send__ "menu_#{menu_name}"
    end
    
    private

    # Clears out the verbs and options array
    def reset_verbs!
      self.verbs = nil
      self.options = []
    end

    # Runs the current menu function to repopulate the verbs and
    # options array with the current state of the object.
    def prepare_current_menu!
      reset_verbs!
      self.__send__ "menu_#{self.current_menu}"
    end

    # Adds a verb to the self.verbs array, from which it will be
    # printed out in TwiML later
    def add_verb(name, text = nil, options = {})
      self.verbs ||= []
      hash = {name: name, text: text, options: options, nested: []}

      if self.nest
        self.verbs.last[:nested] << hash
      else
        self.verbs << hash
      end
    end

    # %w[gather record].each do |key|
    #   define_method key do |options = {}, &block|
    #     add_verb key.capitalize, nil, options
    #     if block_given?
    #       self.nest = true
    #       instance_eval block.call
    #       self.nest = false
    #     end
    #   end
    # end

    # Equivalent of the <Gather> verb
    def gather(options = {})
      add_verb("Gather", nil, options)
      if block_given?
        self.nest = true
        yield
        self.nest = false
      end
    end

    # Equivalent of the <Record> verb
    def record(options = {})
      add_verb("Record", nil, options)
      if block_given?
        self.nest = true
        yield
        self.nest = false
      end
    end


    %w[say play dial number sms].each do |key|
      define_method key do |text, options = {}|
        add_verb key.capitalize, text, options
      end
    end

    # # Equivalent of the <Say> verb
    # def say(text, options = {})
    #   add_verb("Say", text, options)
    # end

    # Equivalent of the <Play> verb
    # def play(url_to_file, options = {})
    #   add_verb("Play", url_to_file, options)
    # end

    # # Equivalent of the <Dial> verb
    # def dial(number = nil, options = {})
    #   add_verb("Dial", number, options)
    # end

    # # Equivalent of the <Number> verb
    # def number(number = nil, options = {})
    #   add_verb("Number", number, options)
    # end

    # # Equivalent of the <Sms> verb
    # def sms(text_to_send, options = {})
    #   add_verb("Sms", text_to_send, options)
    # end

    # Useful for asking the user to make a decision, such as
    # "Press 1 to enter your zipcode."  It registers an option
    # on the current menu, which is then processed by 
    # #process_twilio_response, by comparing the digits the
    # user pressed with the options available.
    #
    # @param number (integer) - the number on the keypad which
    # will trigger the desired action.
    # @param text_to_say (string) - this text will be said by
    # adding a #say action to the menu.
    # @param options (hash) - [:menu, :callback]
    def prompt(number, text_to_say, options = {})
      register_option number, options
      say text_to_say
    end

    # Adds an option to the current menu without saying
    # anything.
    #
    # @see #prompt, #register_option
    #
    # @param number (integer) - the number which will trigger 
    # the transition to the options[:menu] and call the 
    # options[:callback] specified.
    # @param options (hash) - [:menu, :callback]
    def press(number, options = {})
      register_option number, options
    end

    # Actually registers the an option.
    # @see #prompt, #press
    def register_option(number, options = {})
      @options ||= []
      @options << [number, options]
    end

    # Loops through all of the options currently on the object
    # and compares the numbers against the digits param.
    # 
    # If there is a match, it will transition the object to 
    # the given menu for that option, and call the specified
    # callback method with the digits as a parameter.
    #
    # @param digits (integer)
    # @see #process_twilio_response
    def process_options(digits)
      for expected_digits, settings in @options
        if digits.to_i == expected_digits.to_i
          self.__send__ settings[:callback], digits, settings[:value] if settings[:callback]
          transition_to(settings[:menu])
        end
      end
    end

  end
end

ActiveRecord::Base.send :include, Twiliomenu::ActsAsMenu