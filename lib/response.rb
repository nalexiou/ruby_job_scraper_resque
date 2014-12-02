require File.expand_path('../../resque-example-app', __FILE__)
require 'resque/errors'
require 'open-uri'
require 'net/http'
require 'net/https'

# module RetriedJob
#   def on_failure_retry(e, *args)
#     puts "Performing #{self} caused an exception (#{e}). Retrying..."
#     $stdout.flush
#     Resque.enqueue self, *args
#   end
# end



class Response
  @queue = :response
  def self.perform(givenurl, limit, method, hashname="")  
    raise ArgumentError, 'HTTP redirect too deep' if limit == 0
    begin
      @url = URI.parse(givenurl)
      http = Net::HTTP.new(@url.host, @url.port)
      http.read_timeout = 3
      http.open_timeout = 2
      http.use_ssl = (@url.scheme == 'https')
      resp = http.start() do |http|
        http.get(@url.request_uri, 
        {'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36'}
        )
    end
    case resp
      when Net::HTTPSuccess     then send(method, resp, givenurl, hashname) 
      when Net::HTTPRedirection then self.perform(resp['location'], limit - 1, method)
      else
        p resp.error!
      end
      rescue Exception => e
        p e
      end
  end 
  def self.grabnynytmhiring(resp, givenurl, hashname)
    if resp.code.match(/20\d/)
      Nokogiri::HTML(resp.body).css("a").select{|x| x.text == "Hiring"}.each do |y|
        if y['href'] =~ URI::regexp
          redis.sadd "nyhiring", y['href']
        end
            # puts y['href']
        end
    else
      # puts "\tNot a valid page; response was: #{resp.code}"
      # invalidids << resp
    end
  end

  def self.findjobs(resp, givenurl, hashname)
    begin
      if resp.code.match(/(2|3)0\d/)
         regex = redis.get "regex_job_title"
        if !Nokogiri::HTML(resp.body).text.match(/\b(#{regex})s?\b/i).nil?
        # redis.zadd "ny_jobs", Nokogiri::HTML(resp.body).text.downcase.scan(redis.get "regex_job_title")
          # redis.sadd "nyjobs", givenurl
          p match = Nokogiri::HTML(resp.body).text.downcase.scan(/\b(#{regex})s?\b/i)
          p match = match.uniq.flatten.sort.join(" ")
          redis.hset hashname, givenurl, match
        end
      end
      rescue Exception => err
    end
  end


# class Response
#   extend RetriedJob
#   attr_reader :@url
#   @queue = :response

#   def initialize(@url, limit = 10)
#     raise ArgumentError, 'HTTP redirect too deep' if limit == 0
#     @@url = URI.parse(@url)
#     @http = Net::HTTP.new(@@url.host, @@url.port)
#     @http.read_timeout = 3
#     @http.open_timeout = 2
#     @http.use_ssl = (@@url.scheme == 'https')
#   end

#   def get_response
#     begin
#       resp = @http.start() do |http|
#           http.get(@url.request_uri, 
#           {'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36'}
#           )
#         case resp
#           when Net::HTTPSuccess     then redis.lpush(career_url_list, resp.body)
#           when Net::HTTPRedirection then Response.new(resp['location'], limit - 1)
#           else
#             resp.error!
#         end
#       end
#      rescue Exception => e
#     end
#   end

#   def self.perform(@url, limit = 10)
#     (new(@url, limit)).get_response
#   rescue Resque::TermException
#     Resque.enqueue(self, @url, limit)
#   end


  def flush(str)
    puts str
    $stdout.flush
  end

end




# class Watermark
#   extend RetriedJob

#   attr_reader :originals_directory, :watermarked_directory, :connection, :original_file
#   @queue = :watermark

#   def initialize(key)
#     @connection = get_connection
#     @originals_directory = connection.directories.get(ENV['AWS_S3_BUCKET_ORIGINALS'])
#     @watermarked_directory = connection.directories.get(ENV['AWS_S3_BUCKET_WATERMARKED'])

#     @original_file = @originals_directory.files.get(key)
#     flush "Initialized Watermark worker instance"
#   end




#   def self.perform(key)
#     (new key).apply_watermark
#   rescue Resque::TermException
#     Resque.enqueue(self, key)
#   end

#   def apply_watermark
#     Dir.mktmpdir do |tmpdir|
#       tmpfile = File.join(tmpdir, @original_file.key)

#       flush "Opening original file locally: #{tmpfile}"
#       File.open(tmpfile, 'w') { |f| f.write(@original_file.body) }
#       image = MiniMagick::Image.open(tmpfile)

#       result = image.composite(MiniMagick::Image.open("watermark.png", "jpg")) do |c|
#         c.dissolve "15"
#         c.gravity "center"
#       end

#       watermarked_local_file = "#{tmpdir}/watermarked_#{@original_file.key}"
#       result.write(watermarked_local_file)
#       flush "Writing watermarked file locally: #{watermarked_local_file}"

#       save_watermarked_file(watermarked_local_file)
#       redis.incr s3_watermarked_key
#     end 
#   end

#   def save_watermarked_file(watermarked_local_file)
#     watermarked_file_token = @watermarked_directory.files.create(
#       :key    => @original_file.key,
#       :body   => File.open(watermarked_local_file),
#       :public => true
#     )
#     redis.lpush(watermarked_url_list, watermarked_file_token.public_url)
#     flush "Persisted watermarked file to S3: #{watermarked_file_token.public_url}"
#   end


# end
