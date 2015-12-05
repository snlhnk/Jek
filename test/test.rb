ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'
require File.expand_path '../../main.rb', __FILE__

include Rack::Test::Methods

def app
  Sinatra::Application
end

describe '/ に GET した時に' do
  it "Hello と返すこと" do
    get '/'
    assert last_response.ok?
    assert last_response.body.include? 'Hello'
  end
end
