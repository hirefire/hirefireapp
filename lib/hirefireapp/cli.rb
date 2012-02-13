# encoding: utf-8

require "open-uri"
require "openssl"

OpenSSL::SSL.send(:remove_const, :VERIFY_PEER)
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

def usage
  puts
  puts "Usage:"
  puts
  puts "  hirefireapp http://mydomain.com/"
  puts
  puts "Or locally:"
  puts
  puts "  gem install thin"
  puts "  [bundle exec] thin start -p 3000"
  puts "  hirefireapp http://127.0.0.1:3000/"
  puts
  puts "SSL Enabled URLs:"
  puts
  puts "  hirefireapp https://mydomain.com/"
end

if (url = ARGV[0]).nil?
  usage
else
  begin
    response = open(File.join(url, "hirefireapp", "test")).read
  rescue
    puts
    puts "Could not connect to: #{url}"
    usage
    exit 1
  end

  if response =~ /HireFire/
    puts response
  else
    puts "Could not find HireFireApp at #{url}."
    exit 1
  end
end
