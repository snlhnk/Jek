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
    <input type="submit" value="process" />
  </form>
</body>
</html>
