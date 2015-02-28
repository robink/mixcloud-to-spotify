require 'rainbow'
require 'rest_client'

def abort(msg)
  puts Rainbow(msg).color(:red)
  exit
end

# find a user by its user name
def find_user(user_name)
  # begin
    return Mixcloud::User.new("http://api.mixcloud.com/#{user_name}/")
  # rescue Exception => e
    abort("User #{user_name} not found on Mixcloud, aborting. - #{e.inspect}")
  # end
end

# list all cloudcasts for a given cloudcasts url endpoint
def list_cloudcasts(cloudcasts_url, breaker = nil)
  begin
    cloudcasts_result = JSON.parse(RestClient.get cloudcasts_url)
    cloudcasts_url    = cloudcasts_result["paging"].nil? ? nil : cloudcasts_result['paging']['next']
    cloudcasts_data   = cloudcasts_result["data"]

    cloudcasts_data.map do |cloudcast_data|
      cloudcast = Mixcloud::Cloudcast.new 'http://api.mixcloud.com/' + cloudcast_data['key']

      yield cloudcast
    end

  end while !cloudcasts_url.nil?
end

# show information on a given cloudcast instance
# - name
# - tracks
def show_cloudcast(cloudcast, options = {})
  bg = options[:bg] || :red
  puts Rainbow("  + #{cloudcast.name}").background(bg).color(:white)

  cloudcast.sections.each do |section|
    yield(section) if block_given?
  end

  puts ""
end

def show_section(section, &block)
  track = Mixcloud::Track.new(section.track_url)
  show_track(track, &block)
end

def show_track(track, &block)
  artist          = Mixcloud::Artist.new track.artist_url
  full_track_name = "#{track.name} - #{artist.name}"

  puts "    - #{full_track_name}"

  block.call(track.name, artist.name) if block

  puts ""
end

def find_spotify_track(track_name, artist_name, cloudcast_name)
  results = MetaSpotify::Track.search track_name + " " + artist_name

  if results[:tracks].length == 0
    sanitized_track_name  = sanitize(track_name)
    sanitized_artist_name = sanitize(artist_name)

    if track_name != sanitized_track_name || artist_name != sanitized_artist_name
      puts "        < #{Rainbow('Not found, retrying with sanitized track & artist name').color(:red)}"
      find_spotify_track(sanitized_track_name, sanitized_artist_name, cloudcast_name)
    end

    return
  end

  result  = results[:tracks][0]
  artists = result.artists.map{ |a| a.name }.join(", ")

  puts "        > #{result.name} - #{artists} -- #{Rainbow(result.uri).color(:green)}"

  filename = sanitize_filename(cloudcast_name)
  mode     = File.file?("#{filename}.txt") ? "a" : "w"

  File.open("#{filename}.txt", mode) { |file| file.write("#{result.uri}\n") }
end

def sanitize_filename(filename)
  fn = filename.split(/(?<=.)\.(?=[^.])(?!.*\.[^.])/m)
  fn.map! { |s| s.gsub(/[^a-z0-9\-]+/i, '_') }

  return fn.join '.'
end

def sanitize(string)
  string = string.gsub(" ft. ", " ")
  string = string.gsub(" ft ", " ")
  string = string.gsub(" & ", " ")
  string = string.gsub(" x ", " ")
  string = string.gsub(" (", " ")
  string = string.gsub(")", " ")
  string
end
