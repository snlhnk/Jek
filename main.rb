require 'sinatra'
require 'sinatra/reloader'

get "/" do
  erb :index
end

post "/proc" do
  unless params[:file] &&
      (tmpfile = params[:file][:tempfile]) &&
      (name = params[:file][:filename])
    @error = "No file selected"
  end

  send_file(tmpfile, filename: 'test.csv')
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
