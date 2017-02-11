class Tweeter
  include Neo4j::ActiveNode
  include Neo4j::Timestamps

  id_property :twitter_id, on: :get_id
  property :id, type: Integer
  property :url, type: String
  property :name, type: String
  property :verified?, type: Boolean
  property :utc_offset, type: Integer
  property :screen_name, type: String
  property :profile_image_url, type: String

  has_many :out, :following, rel_class: :Follows, unique: true
  has_many :in,  :followers, origin: :following, model_class: :Tweeter, unique: true

  # TODO: These two methods and the class instance variable should not be necessary... :(
  def set_id(_id)
    @id = _id
  end

  def get_id
    @id
  end

  # @param [Twitter::User] twitter_user
  def self.new_from_twitter_user(twitter_user)
    new.tap do |user|
      self.attribute_names.each do |attr|
        user.write_attribute(attr, twitter_user.send(attr)) rescue NoMethodError
      end
      user.set_id(twitter_user.id)
    end
  end
end

class Follows
  include Neo4j::ActiveRel
  include Neo4j::Timestamps

  from_class :Tweeter
  to_class   :Tweeter
  type 'follows'
end
