# encoding: utf-8

Gem::Specification.new do |gem|

  # General configuration / information
  gem.name        = 'hirefireapp'
  gem.version     = '0.0.8'
  gem.platform    = Gem::Platform::RUBY
  gem.authors     = 'Michael van Rooijen'
  gem.email       = 'meskyanichi@gmail.com'
  gem.homepage    = 'http://hirefireapp.com/'
  gem.summary     = %|HireFireApp.com - The Heroku Process Manager - Autoscaling your web and worker dynos!|
  gem.description = %|HireFireApp.com - The Heroku Process Manager - Autoscaling your web and worker dynos saving you time and money!|

  # Files and folder that need to be compiled in to the Ruby Gem
  gem.files         = %x[git ls-files].split("\n")
  gem.executables   = ['hirefireapp']
  gem.require_path  = 'lib'

end
