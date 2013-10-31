require 'rainbow'
require 'rest_client'

def abort(msg)
  puts msg.color(:red)
  exit
end


# find a user by its user name
def find_user(user_name)
  begin
    return Mixcloud::User.new('http://api.mixcloud.com/%s' % user_name)
  rescue
    abort "User %s not found on Mixcloud, aborting." % user_name
  end
end


# list all cloucasts for a given cloudcasts url endpoint
def list_cloudcasts(cloudcasts_url, breaker = nil)
  begin
    cloudcasts_result = JSON.parse(RestClient.get cloudcasts_url)
    cloudcasts_url = cloudcasts_result["paging"].nil? ? nil : cloudcasts_result['paging']['next']
    cloudcasts_data = cloudcasts_result["data"]

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
  puts ("  + " + cloudcast.name).background(bg).color(:white)

  cloudcast.sections.each do |section|
    yield(section) if block_given?
  end

  puts ""
end


def show_section(section, &block)
  track = Mixcloud::Track.new section.track_url
  show_track track, &block
end


def show_track(track, &block)
  artist = Mixcloud::Artist.new track.artist_url
  full_track_name = track.name + " - " + artist.name
  puts "    - " + full_track_name

  block.call(track.name, artist.name) if block

  puts ""
end


def find_spotify_track(track_name, artist_name)
  results = MetaSpotify::Track.search track_name + " " + artist_name

  if results[:tracks].length > 0
    result = results[:tracks][0]
    artists = result.artists.map{ |a| a.name }.join(", ")
    puts "        > " + result.name + " - " +  artists + " -- " + result.uri.color(:green)
  end
end
