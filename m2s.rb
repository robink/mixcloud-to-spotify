require 'highline/import'
require 'meta-spotify'
require 'mixcloud'
require 'rainbow'
require 'rest_client'
require './helpers'

# lookup user
user_name = ask("User?") { |q| q.default = "LeFtOoO"}
cloudcast_name = ask("Cloudcast name?") { |q| q.default = "504" }

# get the user on mixcloud
user = find_user user_name
puts "User #{Rainbow(user_name).color(:green)} found. #{Rainbow(user.cloudcast_count).color(:green)} cloudcasts."

cloudcasts_url = user.cloudcasts_url

puts "#{Rainbow(cloudcasts_url).color(:yellow)}"

puts ""
puts "Lookup for a cloudcast :"
puts ""

list_cloudcasts cloudcasts_url do |cloudcast|
  cloudcast_name_regexp = Regexp.new(cloudcast_name, Regexp::IGNORECASE)

  if cloudcast_name_regexp.match cloudcast.name
    show_cloudcast cloudcast, { bg: :green } do |section|
      show_section section do |track_name, artist_name|
        find_spotify_track(track_name, artist_name, cloudcast.name)
      end
    end

    exit
  end
end
puts 'No Cloudcasts were found that matched your search.'
exit


