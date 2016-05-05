#!/usr/bin/env ruby

require 'webrick'

class CompressableServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET request, response
    case request.path
    when /\.svg(z)?/
      response['Content-Type'] = 'image/svg+xml'
    when /\.htm(l)?/
      response['Content-Type'] = 'text/html'
    when /\.css/
      response['Content-Type'] = 'text/css'
    when /\.js/
      response['Content-Type'] = 'application/javascript'
    else
      response['Content-Type'] = 'text/html'
    end

    local_path = File.join(Dir.pwd, 'work', request.path)
    if File.file? local_path
      response.status = 200
      response.body = File.read(local_path)
    elsif Dir.exists? local_path and File.exists? File.join(local_path, 'index.html')
      response.status = 200
      response.body = File.read(File.join(local_path, 'index.html'))
    else
      response.status = 404
      response.body = "Not found: #{request.path}"
      response['Content-Type'] = 'text/plain'
    end

    if response.body[0..1].bytes == [0x1f, 0x8b]
      response['Content-Encoding'] = 'gzip'
    end
  end
end

server = WEBrick::HTTPServer.new :Port => 8000, :DocumentRoot => Dir.pwd
server.mount '/', CompressableServlet

server.start
