require 'sinatra'
require 'sinatra/reloader'

get "/" do
  erb :index
end

__END__

@@ index
<html>
<body>
Hello, world
</body>
</html>
