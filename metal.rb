require 'rubygems'

require 'uri'
require 'rss/1.0'
require 'rss/2.0'
require 'hpricot'
require 'launchy'
require 'tempfile'  
require 'net/http'
require 'open-uri'
require 'rest_client'

rollio = 'http://roll.io'
source = 'http://www.reddit.com/r/Metal/.rss'
post_url = 'http://roll.io/includes/fileupload.php'
controller_url = 'http://roll.io/controller/controller.php'

content = '' # raw content of rss feed will be loaded here
open(source) do |s| content = s.read end
rss = RSS::Parser.parse(content, false)
temp_file = Tempfile.new(['random','.txt'], '/tmp')

rss.items.each do |item|
  if item.description.downcase.include? 'youtube.com'
    Hpricot(item.description).search('a').each do |link|
      if link.attributes['href'].downcase.include? 'youtube'
        youtube_link = link.attributes['href']
        temp_file.print(youtube_link, "\n")
      end
    end
  end
end

temp_file.flush()

begin
  post_response = RestClient.post post_url, :uploaded_file => File.new(temp_file.path, 'rb')
rescue => e

  # redirects throw an exception, so continue here

  # GET roll.io controller action to get hashtag using previous cookie
  params = { :params => { :action => 'playlist' }, :cookies => e.response.cookies }
  controller_response = RestClient.get controller_url, params
  hashtag = Hpricot(controller_response).search('li')[0].attributes['hashtag']

  playlist_url = "#{rollio}/##{hashtag}"
  Launchy.open(playlist_url)

end
