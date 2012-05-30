# Twiliomenu

If you've spent any time with Twilio, you know that you can end up with a lot of controller actions.  A lot of logic ends up in the controller, which isn't a recipe for DRY or maintainable code.

This gem allows you to move most of your [Twilio](http://twilio.com) code into your model rather than a mess of controller actions.

### For Example
Some of your twilio controllers might look like this:

	class CallController < ActionController::Base
	  def handler
	    # If the user has pressed digits on their keypad,
	    # process them.
	    if params[:Digits]
	      if params[:Digits] == 1
	        response = Twilio::Builder do |r|
	          r.redirect second_menu_path
	        end
	      elseif params[:Digits] == 2
	        response = Twilio::Builder do |r|
	          r.redirect third_menu_path
	        end
	      end
	    
	    # Otherwise, display the first menu
	    else  
	      response = Twilio::Builder do |r|
	        r.play "/path-to-sound.mp3"
	        r.say "This is the handler menu."
	        r.gather do
	          r.say "Press 1 to go to the second menu"
	          r.say "Press 2 to go to the third menu"
	        end
	      end
	    end
	    
	    render text: response
	  end
	  
	  def second_menu
	    # Second menu code would go here ...
	  end
	  
	  def third_menu
	    # More code here ...
	  end
	end

Ick.  This design results in a lot logic residing in your controllers, and as the controller grows, it will difficult to follow.

Here's how we'd refactor this code with twiliomenu.

### Install the gem

	gem install twiliomenu

Or inside your Gemfile:
	
	gem "twiliomenu"

Then run `bundle install` to install it.

### Call Model
First, generate your model.
	
	rails g model Call current_menu

**Note** that you need to add a string field named "current_menu" to any model you wish to use this gem with.  Now, inside our **call_model.rb** we can write:

	class Call < ActiveRecord::Base
	  acts_as_menu # Pulls in the gem functionality
	  
	  menu :opening_menu do
	  	play "/path-to-sound.mp3"
	  	say "This is the handler menu."
	  	gather do
	  	  prompt 1, "Press 1 to go to the second menu", menu: :second_menu
	  	  prompt 2, "Press 2 to go to the third menu", menu: :third_menu
	  	end
	  end
	  
	  menu :second_menu do
	    # Code for the second menu here ...
	  end
	  
	  menu :third_menu do
	    # Code for the third menu here ...
	  end
	end
	
And then we can slim down our controller!

	class CallController < ActiveController::Base
	  def handler
	    @call = (params[:id]) ? Call.find(params[:id]) : Call.create
	    @call.process_twilio_response(params)
	    render text: @call.twiml
	  end
	end