require 'rubygems'
require 'sinatra/base'
require 'json'
require 'nokogiri'
require 'showoff_utils'
require 'showoff_engine'

begin 
  require 'rdiscount'
rescue LoadError
  require 'bluecloth'
  Markdown = BlueCloth
end
require 'pp'

class ShowOff < Sinatra::Application

  set :views, File.dirname(__FILE__) + '/../views'
  set :public, File.dirname(__FILE__) + '/../public'
  set :pres_dir, 'example'

  def initialize(app=nil)
    super(app)
    puts dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))
    if Dir.pwd == dir
      options.pres_dir = dir + '/example'
    else
      options.pres_dir = Dir.pwd
    end
    puts options.pres_dir
  end

  helpers ShowOffEngine::Helpers

  get '/' do
    erb :index, :pres_dir => options.pres_dir
  end

  get %r{(?:image|file)/(.*)} do
    path = params[:captures].first
    full_path = File.join(options.pres_dir, path)
    send_file full_path
  end

  get '/slides' do
    index = File.join(options.pres_dir, 'showoff.json')
    files = []
    if File.exists?(index)
      order = JSON.parse(File.read(index))
      order = order.map { |s| s['section'] }
      order.each do |section|
        files << load_section_files(section, options.pres_dir)

      end
      files = files.flatten
      files = files.select { |f| f =~ /.md/ }
      data = ''
      files.each do |f|
        fname = f.gsub(options.pres_dir + '/', '').gsub('.md', '')
        data += process_markdown(fname, File.read(f))
      end
    end
    data
  end
  
  post '/code' do 
    rv = eval(params[:code])
    return rv.to_s
  end

end
