# encoding: utf-8

Gem::Specification.new do |gem|

  # General configuration / information
  gem.name        = 'hirefireapp'
  gem.version     = '0.0.1'
  gem.platform    = Gem::Platform::RUBY
  gem.authors     = 'Michael van Rooijen'
  gem.email       = 'meskyanichi@gmail.com'
  gem.homepage    = 'http://hirefireapp.com/'
  gem.summary     = %|HireFireApp.com - The Heroku Worker Monitor - Save money and scale at the same time!|
  gem.description = %|HireFireApp.com - The Heroku Worker Monitor - Save money and scale at the same time! We monitor your applications by the minute!|

  # Files and folder that need to be compiled in to the Ruby Gem
  gem.files         = %x[git ls-files].split("\n")
  gem.executables   = ['hirefireapp']
  gem.require_path  = 'lib'

end