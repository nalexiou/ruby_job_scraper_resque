require 'bundler/setup'
Bundler.require(:default)
require File.expand_path('../lib/response', __FILE__)
require 'sinatra/redis'
require 'nokogiri'
require 'pry'


configure do
  redis_url = ENV["REDISCLOUD_URL"] || ENV["OPENREDIS_URL"] || ENV["REDISGREEN_URL"] || ENV["REDISTOGO_URL"]
  uri = URI.parse(redis_url)
  Resque.redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
  # Resque.redis.namespace = "resque:example"
  set :redis, redis_url
end

get '/' do
  erb :form
end

post '/search' do
  redis.incr "mycounter"
  $uniqueid = redis.get "mycounter"
  $hashname = "nyjobhash#{$uniqueid.to_s}"
  redis.del "nyjobs"
  redis.set "keywords", params[:keywords]
  keywords_array = (redis.get "keywords").scan(/'.*?'|".*?"|\S+/)
  keywords_regex = keywords_array.join("|")
  # redis.set "regex_job_title", /\b(#{keywords_regex})s?\b/i
  redis.set "regex_job_title", keywords_regex

  # $careerlinksverified = []


  # p lastpage = Nokogiri::HTML(open("https://nytm.org/made?list=true")).at_css("div.digg_pagination > a:nth-last-child(2)").text.to_i
  
  (1..26).each do |id|
  redis.sadd "nytc", "https://nytm.org/made?list=true&page=#{id}"
  end
  (redis.smembers "nytc").each do |url|
    Resque.enqueue(Response, url, 10, "grabnynytmhiring" )
  end
  sleep(3)
  @working = Resque.working
  @nyhiringlist = redis.smembers "nyhiring"
  erb :index

end

get '/search' do
  @working = Resque.working
  @nyhiringlist = redis.smembers "nyhiring"
  erb :index
end


post "/jobs" do
  (redis.smembers "nyhiring").each do |url|
    Resque.enqueue(Response, url, 10, "findjobs", $hashname )
  end
  @working = Resque.working
  @nyhiringlist = redis.smembers "nyhiring"
  sleep(3)
  erb :jobs
end

get "/jobs" do

  @working = Resque.working
  @nyhiringlist = redis.smembers "nyhiring"
  erb :jobs

end

get "/results" do
  @working = Resque.working
  @nyjobs = redis.hgetall $hashname
  erb :results

end

# post "/results" do

#   nytmurls =[]

#   #GET LAST PAGE OF COMPANIES
#  lastpage = Nokogiri::HTML(open("https://nytm.org/made?list=true")).at_css("div.digg_pagination > a:nth-last-child(2)").text.to_i

#  (1..lastpage).each do |id|
#   nytmurls << "https://nytm.org/made?list=true&page=#{id}"
#   end
   
#   nytmurls.each do  |url|
#     redis.set "mytest", url
#     redis.sadd "mytest3", url
#     redis.lpush "mytest2", url
#     Resque.enqueue(Response, url, 10)
#   end
  
#   p "this is resque working #{Resque.working.length}"
#   # p redis.get "mytest"
#   # redis.lpush(career_url_list, "mytest")
#   # @career_urls = redis.get career_url_list
#   # @working = Resque.working
#   # erb :index
#   redirect "/search"
# end

# get "/search" do
#     @mylist = redis.lrange "mytest2", 0, -1
#     @mylist2 = redis.smembers "mytest3"
#     @working = Resque.working
#      erb :index
# end

# end

# post '/upload' do
#   unless params['file'][:tempfile].nil?
#     tmpfile = params['file'][:tempfile]
#     name = params['file'][:filename]
#     redis.incr local_uploads_key
#     file_token = send_to_s3(tmpfile, name)
#     Resque.enqueue(Watermark, file_token.key)
#   end
# end

# def send_to_s3(tmpfile, name)
#   connection = Fog::Storage.new({
#     :provider => 'AWS',
#     :aws_access_key_id => ENV['AWS_ACCESS_KEY_ID'],
#     :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
#   })

#   directory = connection.directories.get(ENV['AWS_S3_BUCKET_ORIGINALS'])
#   file_token = directory.files.create(
#     :key    => name,
#     :body   => File.open(tmpfile),
#     :public => true
#   )
#   redis.incr s3_originals_key
#   file_token
# end
