require 'sinatra'
require 'sinatra/reloader'
require './csv2pdf'

def make_pdf(people)
  pdf = Pdf.new
  output_file = "./tmp/result.pdf"

  n = people.length
  people.each do |p|
    pdf.stroke_address(p)
    n -= 1
    pdf.start_new_page if n > 0
  end

  pdf.render_file(output_file)
  send_file(output_file, filename: File.basename(output_file))
end

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
  @errors = Array.new
  csv.each do |c|
    begin
      people << Person.new(c)
    rescue
      @errors << c
    end
  end

  if @errors.length == 0
    make_pdf(people)
  else
    erb :proc_error
  end
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

@@ proc_error
<html>
<body>
<h1>error</h1>
以下のデータはPDFに変換できませんでした。
<hr>
<% @errors.each do |e| %>
  <%= e.to_s %>
<% end %>
</body>
</html>
