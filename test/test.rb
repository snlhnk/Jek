ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'
require 'digest/md5'
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
    md[0].must_match /POST/
    md[0].must_match /\/proc/
  end
end

describe '/proc に csv を POST した時に' do
#  title_row = "kana,name,title,zip,addr1,addr2,family1,title1,family2,title2"
  data1_row = "やまだ,山田 太郎,様,100-0014,東京都千代田区永田町1丁目7-1,,,,,"
  csv_file1 = "tmp/upload_csv1.csv"
  data2_row = "さとう,佐藤 花子,様,102-8651,東京都千代田区隼町4−2100-0014,最高裁判所内,二郎,様,,"
  csv_file2 = "tmp/upload_csv2.csv"

  def create_sample_file(filename, data)
    File.delete(filename) if File.exist?(filename)
    File.open(filename, 'w') do |f|
      f.puts data
    end
  end
 
  before do
    create_sample_file(csv_file1, data1_row)
    create_sample_file(csv_file2, data2_row)
  end

  it 'response が attachment である(ダウンロードの形式になっている)こと' do
    post '/proc' ,'file' => Rack::Test::UploadedFile.new(csv_file1,\
         'text/csv')
    assert last_response.ok?
    last_response.header["Content-Disposition"].must_match /attachment/
  end

  it 'download されるファイルが pdf であること' do
    post '/proc' ,'file' => Rack::Test::UploadedFile.new(csv_file1,\
         'text/csv')
    last_response.body.must_match /^%PDF/
  end

  it '異なるデータからは異なる pdf が作られること' do
    post '/proc' ,'file' => Rack::Test::UploadedFile.new(csv_file1,\
         'text/csv')
    download1_md5 = Digest::MD5.hexdigest(last_response.body)
    post '/proc' ,'file' => Rack::Test::UploadedFile.new(csv_file2,\
         'text/csv')
    download2_md5 = Digest::MD5.hexdigest(last_response.body)
    download1_md5.wont_equal download2_md5
  end
end

