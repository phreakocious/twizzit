require 'neo4j'
require 'neo4j/session_manager'

require_relative 'models'

Neo4j::ActiveBase.on_establish_session do
  #adaptor = Neo4j::Core::CypherSession::Adaptors::Bolt.new('bolt://neo4j:twizzit@localhost:7687', wrap_level: :proc)
  adaptor = Neo4j::Core::CypherSession::Adaptors::HTTP.new('http://neo4j:twizzit@localhost:7474', wrap_level: :proc)
  Neo4j::Core::CypherSession.new(adaptor)
end

class Purger
  observed = 0
  destroyed = 0
  at_exit { printf "observed: %d, destroyed: %d\n", observed, destroyed }

  Tweeter.find_each(batch_size: 100) do |tweeter|
    observed += 1
    following = tweeter.following.count
    printf "@%s %d ", tweeter.screen_name, following
    if following == 0
        followers = tweeter.followers.count
        if followers == 0
          tweeter.destroy
          destroyed += 1
        end
    end
    puts followers
  end
end

