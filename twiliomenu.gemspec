$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "twiliomenu/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "twiliomenu"
  s.version     = Twiliomenu::VERSION
  s.authors     = ["Daniel Berkompas"]
  s.email       = ["daniel@managemyproperty.com"]
  s.homepage    = ""
  s.summary     = "Twilio without the messy controller actions."
  s.description = "DRY up your twilio integration code by moving the majority of it into the model."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.3"
  s.add_dependency "twilio-rb"

  s.add_development_dependency "sqlite3"
end
