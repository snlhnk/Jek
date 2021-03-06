ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'
require 'tilt/erb'
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

def create_sample_file(filename, data_array)
  File.delete(filename) if File.exist?(filename)
  File.open(filename, 'w') do |f|
    data_array.each do |d|
      f.puts d
    end
  end
end

def write_pdf(filename, pdfdata)
  File.delete(filename) if File.exist?(filename)
  File.open(filename, 'w') do |f|
    f.puts pdfdata
  end
end

describe '/proc に有効な csv を POST した時に' do
  data1 = "やまだ,山田 太郎,様,100-0014,東京都千代田区永田町1丁目7-1,,,,,"
  data2 = "さとう,佐藤 花子,様,102-8651,東京都千代田区隼町4-2100-0014,最高裁判所内,二郎,様,,"
  csv_file1 = "tmp/upload_csv1.csv"
  csv_file2 = "tmp/upload_csv2.csv"

  before do
    create_sample_file(csv_file1, [data1])
    create_sample_file(csv_file2, [data2])
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
    last_response.header["Content-Type"].must_include "application/pdf"
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

describe '/proc に不正な csv を POST した時に' do
  data_invalid1 = "やまだ,,様,100-0014,東京都千代田区永田町1丁目7-1,,,,," # 宛名なし
  data_invalid2 = "すずき,鈴木 太郎,様,100-0014,,,,,," # 住所なし
  data_valid = "さとう,佐藤 花子,様,102-8651,東京都千代田区隼町4-2100-0014,最高裁判所内,二郎,様,,"
  csv_file = "tmp/upload_csv1.csv"

  it 'response が attachment でない(ダウンロードの形式でない)こと' do
    create_sample_file(csv_file, [data_invalid1])
    post '/proc' ,'file' => Rack::Test::UploadedFile.new(csv_file,\
         'text/csv')
    assert last_response.ok?
    last_response.header["Content-Disposition"].wont_match /attachment/
  end

  it 'response が エラーメッセージで、不正なデータを表示すること' do
    create_sample_file(csv_file, [data_invalid1])
    post '/proc' ,'file' => Rack::Test::UploadedFile.new(csv_file,\
         'text/csv')
    last_response.body.must_match /[Ee]rror/
    last_response.body.must_match Regexp.new(data_invalid1[0..2])
  end

  it '複数データの際も同様にエラーメッセージを出して、不正データを表示し、正規データを表示しないこと' do
    create_sample_file(csv_file, [data_valid, data_invalid2])
    post '/proc' ,'file' => Rack::Test::UploadedFile.new(csv_file,\
         'text/csv')
    assert last_response.ok?
    last_response.body.must_match /[Ee]rror/
    last_response.body.wont_match Regexp.new(data_valid[0..2])
    last_response.body.must_match Regexp.new(data_invalid2[0..2])
  end

  it '正規データがない場合、ダウンロードリンクを表示しないこと' do
    create_sample_file(csv_file, [data_invalid1])
    post '/proc' ,'file' => Rack::Test::UploadedFile.new(csv_file,\
         'text/csv')
    last_response.body.wont_match /href.*download/
  end

  it '正規データがある場合、ダウンロードリンクを表示すること' do
    create_sample_file(csv_file, [data_valid, data_invalid2])
    post '/proc' ,'file' => Rack::Test::UploadedFile.new(csv_file,\
         'text/csv')
    last_response.body.must_match /href.*download/
  end
end

describe '/proc に有効だが不完全な csv を POST した時に' do
  require 'poppler'
  data_correct = "やまだ,山田 太郎,様,100-0014,東京都千代田区永田町1丁目7-1,,,,,"
  csv_file = "tmp/upload_csv.csv"
  pdf_file = "tmp/download.pdf"

  before do
    create_sample_file(csv_file, [data_correct])
    post '/proc' ,'file' => Rack::Test::UploadedFile.new(csv_file,\
         'text/csv')
    write_pdf(pdf_file, last_response.body)
    @download_correct_md5 = Digest::MD5.hexdigest\
      (Poppler::Document.new(pdf_file).get_page("1").get_text)
  end

  it '郵便番号に〒マークが入っていても正しく pdf が作成されること' do
    create_sample_file(csv_file, \
                  [data_correct.gsub('100-0014', '〒100-0014')])
    post '/proc' ,'file' => Rack::Test::UploadedFile.new(csv_file,\
         'text/csv')
    assert last_response.ok?
    last_response.header["Content-Disposition"].must_match /attachment/
    last_response.body.must_match /^%PDF/
    last_response.header["Content-Type"].must_include "application/pdf"
    write_pdf(pdf_file, last_response.body)
    download_incorrect_md5 = Digest::MD5.hexdigest\
      (Poppler::Document.new(pdf_file).get_page("1").get_text)
    download_incorrect_md5.must_equal @download_correct_md5
  end

  it '敬称が空欄でも様をつけて pdf が作成されること' do
    create_sample_file(csv_file, [data_correct.gsub('様', '')])
    post '/proc' ,'file' => Rack::Test::UploadedFile.new(csv_file,\
         'text/csv')
    assert last_response.ok?
    last_response.header["Content-Disposition"].must_match /attachment/
    last_response.body.must_match /^%PDF/
    last_response.header["Content-Type"].must_include "application/pdf"
    write_pdf(pdf_file, last_response.body)
    download_incorrect_md5 = Digest::MD5.hexdigest\
      (Poppler::Document.new(pdf_file).get_page("1").get_text)
    download_incorrect_md5.must_equal @download_correct_md5
  end
end
