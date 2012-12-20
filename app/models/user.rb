# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  email      :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# 참고 : http://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html#method-i-has_many

class User < ActiveRecord::Base
  attr_accessible :email, :name, :password, :password_confirmation
  has_secure_password
  #dependent 옵션은 User가 삭제될때, Micropost도 삭제하도록 하는 옵션 
  has_many :microposts, dependent: :destroy
  #relationship과 1:n의 관계에서 나를 가리키게 할 key를 정할때, foreign_key를 쓴다.
  has_many :relationships, foreign_key: "follower_id", dependent: :destroy
  #본 객체의 followed_users라는 변수를 선언하면서, relationship이라는 객체를 이용할 것이다.
  #따라서 relationships에서 follower_id가 현재 객체인 녀석들을 잡아서, 해당 row의 followed 컬럼에 있는 녀석들을 followed_user로 받아낸다.
  #relationship클래스 내에 followed가 user클래스로 되어있기 때문에 객체 타입은 문제가 없다.
  has_many :followed_users, through: :relationships, source: :followed
  #위의 relationship의 반대버전이다. follower_id대신에 followed_id를 키로 사용하고 있고,
  #reverse_relationship으로 클래스를 찾을수 없기 때문에 class_name으로 클래스명을 찾아주었다.
  has_many :reverse_relationships, foreign_key: "followed_id",
                                   class_name:  "Relationship",
                                   dependent:   :destroy
  #본클래스를 follow하는 사용자들이다. 
  #reverse_relationships를 through로 설정하였고, 해당 클래스의 follower를 잡아서 has_many로 넣어준다.
  has_many :followers, through: :reverse_relationships, source: :follower
  before_save { |user| user.email = email.downcase }
  before_save :create_remember_token
  
  validates :name, presence:true, length: {maximum:50}
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence:true, format: {with:VALID_EMAIL_REGEX}, 
            uniqueness:{case_sensitive:false}
  validates :password, presence: true, length: { minimum: 6 }
  validates :password_confirmation, presence: true
   
  def feed
    # This is preliminary. See "Following users" for the full implementation.
    Micropost.where("user_id = ?", id)
  end
  def following?(other_user)
    relationships.find_by_followed_id(other_user.id)
  end

  def follow!(other_user)
    relationships.create!(followed_id: other_user.id)
  end

  def unfollow!(other_user)
    relationships.find_by_followed_id(other_user.id).destroy
  end
  private 
    def create_remember_token
      self.remember_token = SecureRandom.urlsafe_base64
    end
end
