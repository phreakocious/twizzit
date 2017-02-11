require 'neo4j'
require 'neo4j/session_manager'
require 'twitter'
require 'pp'

require_relative 'models'

USER_SLEEP = 0.25      # Wait this long between processing users.  Helps avoid the API rate limit.
MAX_FOLLOWING = 8000   # Users following more than this many others will be ignored.
RESCAN_THRESHOLD = 3   # Rescan user if database/Twitter following counts differ by more than this. (TODO: naive)

# TODO - unfollows, edge attributes (active dates?)

trap 'SIGINT' do exit 1 end

$config = YAML.load_file('config.yml') rescue abort('Error reading config.yml.')
$config.symbolize_keys!

Neo4j::ActiveBase.on_establish_session do
  adaptor = Neo4j::Core::CypherSession::Adaptors::HTTP.new($config[:neo4j_url], wrap_level: :proc)
  Neo4j::Core::CypherSession.new(adaptor)
end

def twitter_client
  Twitter::REST::Client.new($config[:twitter])
end

# @param [Twitter::User] twitter_user
def find_or_create_node(twitter_user)
  tweeter = Tweeter.find_by_id twitter_user.id
  if tweeter printf "!" else
    tweeter = Tweeter.new_from_twitter_user twitter_user
    tweeter.save
    printf "."
  end
  tweeter
end

SLICE_SIZE = 500
def fetch_all_following(screen_name)
  following = []
  begin
    twitter_client.friend_ids(screen_name).each_slice(SLICE_SIZE) do |slice|

      twitter_client.users(slice).each do |f|
        following << f
        printf 't'
        sleep USER_SLEEP
      end
      printf "T"
    end
  rescue Twitter::Error::TooManyRequests => error
    reset_time = error.rate_limit.reset_in + 1
    printf "-#{reset_time}-"
    sleep reset_time
    retry
  rescue Twitter::Error::ServiceUnavailable => error
    printf '+'
    sleep 30
    retry
  end
  puts
  following
end

def do_following(screen_name)
  printf "@%s ", screen_name
  twitter_user = twitter_client.user screen_name
  begin
    twitter_user = twitter_client.user screen_name
  rescue => error
    abort("Couldn't load screen name #{screen_name} -- #{error.to_s}") unless @tweeter
    printf "+"; sleep 5
    retry
  end
  return unless @tweeter == nil || twitter_user.friends_count < MAX_FOLLOWING
  tweeter = find_or_create_node twitter_user
  count_diff = twitter_user.friends_count - tweeter.following.count

  return tweeter if count_diff < 3
  printf " %d !~ %d ", tweeter.following.count, twitter_user.friends_count
  following = []

  fetch_all_following(screen_name).each do |f|
    following << find_or_create_node(f)
  end

  printf "#"
  tweeter.following << (following - tweeter.following.to_a)

  tweeter
end

class Twizzit
  screen_name = ARGV.shift || abort('Please specify a screen name to start from.')

  @tweeter = do_following screen_name

  @tweeter.following.to_a.shuffle.each do |f|
    do_following f.screen_name
    puts
  end
end

