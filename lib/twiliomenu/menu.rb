# Twilio Menu
# @copyright 2012, ManageMyProperty
# @author Daniel Berkompas
# @license No distribution allowed
module TwilioMenu

  # Class Modifications
  # The following functions modify the class which includes this
  # module.  They add an attribute accessors to the class, an
  # after_initialize hook to set these attributes with default 
  # values.
  def self.included(klass)
    klass.extend MenuClassMethods # Adds class methods to the class
    
    klass.instance_eval do
      attr_accessor :verbs, :nest, :menus, :options, :twilio
      alias_method :go_to_menu, :transition_to

      after_initialize :set_defaults

      define_method :set_defaults do
        self.current_menu = :opening_menu if self.current_menu.nil?
        self.options = []
        self.twilio = {}
        self.send("menu_#{self.current_menu}")
      end
    end
  end

  # Menu Class Methods
  # Container for methods that should be on the class, not just
  # each instance.  See #self.included
  module MenuClassMethods

    # Adds a menu function to the class.  It's simply a shortcut
    # method to defining a method with the name menu_#{name_here}
    # with the code block included in the menu call.
    #
    # It uses instance_eval to make sure that the block is 
    # executed in the **current** context of the class, not the
    # context that existed at the time the menu was defined.
    #
    # This allows you to change a menu's behavior based on
    # conditions which are evaluated against the current state
    # of the class, rather than the state it was in when it
    # was instantiated.
    def menu(name, &block)
      define_method "menu_#{name.to_s}" do |twilio = nil|
        self.instance_eval(&block)
      end
    end
  end
  
  # End Class Modifications
  # --------------------------------------------------------------

  # Instance Methods
  # The following are simple instance methods, not class methods.
  # They will be mixed in to the including class simply by the
  # #include method.

  # Renders TwiML for the object based on the current menu.
  def twiml
    prepare_current_menu!

    Twilio::TwiML.build do |r|
      for verb in self.verbs[:actions] do
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
    allows_nesting = ["Gather", "Dial"]

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
  def process_twilio_response(twilio = nil)
    @twilio = twilio
    prepare_current_menu!
    process_options(@twilio[:Digits]) if @twilio
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

  def add_verb(name, text = nil, options = {})
    self.verbs ||= {actions: [], prompts: []}
    hash = {name: name, text: text, options: options, nested: []}

    if self.nest
      self.verbs[:actions].last[:nested] << hash
    else
      self.verbs[:actions] << hash
    end
  end

  def gather(options = {})
    add_verb("Gather", nil, options)
    if block_given?
      self.nest = true
      yield
      self.nest = false
    end
  end

  def record(options = {})
    add_verb("Record", nil, options)
    if block_given?
      self.nest = true
      yield
      self.nest = false
    end
  end

  def say(text, options = {})
    add_verb("Say", text, options)
  end

  def play(url_to_file, options = {})
    add_verb("Play", url_to_file, options)
  end

  def dial(number = nil, options = {})
    add_verb("Dial", number, options)
  end

  def number(number = nil, options = {})
    add_verb("Number", number, options)
  end

  def prompt(number, text_to_say, options = {})
    register_option number, options
    say text_to_say
  end

  def press(number, options)
    register_option number, options
  end

  def register_option(number, options)
    @options ||= []
    @options << [number, options]
  end

  def process_options(digits)
    for expected_digits, settings in @options
      if digits.to_i == expected_digits.to_i
        self.__send__ settings[:callback], digits if settings[:callback]
        transition_to(settings[:menu])
      end
    end
  end

end