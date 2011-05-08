# encoding: utf-8

Gem::Specification.new do |gem|

  # General configuration / information
  gem.name        = 'hirefireapp'
  gem.version     = '0.0.1'
  gem.platform    = Gem::Platform::RUBY
  gem.authors     = 'Michael van Rooijen'
  gem.email       = 'meskyanichi@gmail.com'
  gem.homepage    = 'http://hirefireapp.com/'
  gem.summary     = %|HireFireApp.com automatically "hires" and "fires" (aka "saving money" and "scaling") Delayed Job and Resque workers on Heroku.|
  gem.description = %|HireFireApp.com automatically "hires" and "fires" (aka "saving money" and "scaling") Delayed Job and Resque workers on Heroku. When there are no queue jobs, HireFire will fire (shut down) all workers. If there are queued jobs, then it'll hire (spin up) workers. The amount of workers that get hired depends on the amount of queued jobs (the ratio can be configured by you). HireFire is great for both high, mid and low traffic applications. It can save you a lot of money by only hiring workers when there are pending jobs, and then firing them again once all the jobs have been processed. It's also capable to dramatically reducing processing time by automatically hiring more workers when the queue size increases.|

  # Files and folder that need to be compiled in to the Ruby Gem
  gem.files         = %x[git ls-files].split("\n")
  gem.require_path  = 'lib'

end