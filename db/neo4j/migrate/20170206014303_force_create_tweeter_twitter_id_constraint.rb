class ForceCreateTweeterTwitterIdConstraint < Neo4j::Migrations::Base
  def up
    add_constraint :Tweeter, :twitter_id, force: true
  end

  def down
    drop_constraint :Tweeter, :twitter_id
  end
end
