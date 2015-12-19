require 'sinatra'
require 'sinatra/reloader'
require './csv2pdf'

get "/" do
  erb :index
end

post "/proc" do
  unless params[:file] &&
      (tmpfile = params[:file][:tempfile]) &&
      (name = params[:file][:filename])
    @error = "No file selected"
  end

  csv = CSV.open(tmpfile)
  people = Array.new
  csv.each do |c|
    people << Person.new(c)
  end

  pdf = Pdf.new

  n = people.length
  people.each do |p|
    pdf.stroke_address(p)
    n -= 1
    pdf.start_new_page if n > 0
  end

  pdf.render_file("./tmp/result.pdf")

  send_file('./tmp/result.pdf', filename: 'result.pdf')
end

__END__

@@ index
<html>
<body>
  <form action="/proc" method="POST" enctype="multipart/form-data">
    <input type="file" name="file" />
    <input type="submit" value="pdf 作成" />
  </form>
<hr>
<h1>使い方</h1>
宛名 csv ファイルをアップロードすると郵便はがき用宛名 pdf を返します。<br>
宛名 csv ファイルには次の項目を記載してください。文字コードはUTF-8で記載してください。

<ol>
  <li>ふりがな
  <li>氏名
  <li>敬称
  <li>郵便番号
  <li>住所1
  <li>住所2(マンション名など)
  <li>併記家族(1)
  <li>その敬称(1)
  <li>併記家族(2)
  <li>その敬称(2)
</ol>
</body>
</html>
