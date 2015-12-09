ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'
require File.expand_path '../../main.rb', __FILE__

include Rack::Test::Methods

def app
  Sinatra::Application
end

describe '/ に GET した時に' do
  it "/proc に POST する入力フォームを表示すること" do
    get '/'
    assert last_response.ok?
    md = last_response.body.match(/<\w*form.+>/)
    assert md[0].include?("POST")
    assert md[0].include?("/proc")
  end
end

describe '/proc に csv を POST した時に' do
  upload_csv = "tmp/upload_csv.csv"
  title_row = "col1, col2, col3"
  data_row = "data1, data2, data3"
 
  before do
    File.delete(upload_csv) if File.exist?(upload_csv)
    File.open(upload_csv, 'w') do |f|
      f.puts title_row
      f.puts data_row
    end
  end

  it 'upload したファイルの内容が表示されること' do
    post '/proc' ,'file' => Rack::Test::UploadedFile.new(upload_csv,\
         'text/csv')
    assert last_response.ok?
    assert last_response.body.include?(title_row)
    assert last_response.body.include?(data_row)
  end
end

