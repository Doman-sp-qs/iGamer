class Customer < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  # アソシエーション設定
  has_many :posts, dependent: :destroy
  has_many :post_comments, dependent: :destroy
  has_many :favorites, dependent: :destroy
  
  has_many :relationships, class_name: "Relationship", foreign_key: "follower_id", dependent: :destroy
  has_many :reverse_of_relationships, class_name: "Relationship", foreign_key: "followed_id", dependent: :destroy
  
  has_many :followings, through: :relationships, source: :followed
  has_many :followers, through: :reverse_of_relationships, source: :follower
  
  # プロフィールカラム設定
  has_one_attached :profile_image
  
  # バリデーション
  validates :name, presence: true, length: {minimum: 2, maximum: 20}, uniqueness: true
  validates :introduction, length: {maximum: 160}
  
  # プロフィール画像の取得、サイズ変更用
  def get_profile_image(width, height)
    unless profile_image.attached?
      # プロフィール画像が設定されていない時
      file_path = Rails.root.join('app/assets/images/no_image.jpg')
      profile_image.attach(io: File.open(file_path), filename: 'no_image.jpg', content_type: 'image/jpeg')
    end
    # プロフィール画像のサイズ変更用
    profile_image.variant(resize_to_limit: [width, height]).processed
  end
  
  # フォローフォロワー機能
  def follow(customer_id)
    relationships.create(followed_id: customer_id)
  end
  
  def unfollow(customer_id)
    relationships.find_by(followed_id: customer_id).destroy
  end
  
  def following?(customer)
    followings.include?(customer)
  end
  
  # customerの利用停止ステータスの判定
  def is_stopping?(customer)
    customers.exists?(is_stopping: true)
  end
  
  # 検索方法分岐
  def self.looks(search, word)
    if search == "perfect_match"
      @customer = Customer.where("name LIKE?","#{word}")
    elsif search == "forward_match"
      @customer = Customer.where("name LIKE?","#{word}%")
    elsif search == "backward_match"
      @customer = Customer.where("name LIKE?","%#{word}")
    elsif search == "partial_match"
      @customer = Customer.where("name LIKE?","%#{word}%")
    else
      @customer = Customer.all
    end
  end
  
  # ゲストログイン用
  def self.guest
    find_or_create_by!(name: "ゲストユーザ", email: 'guest@example.com') do |customer|
      customer.password = SecureRandom.urlsafe_base64
      # customer.confirmed_at = Time.now  # Confirmable を使用している場合は必要
      # 例えば name を入力必須としているならば， customer.name = "ゲスト" なども必要
    end
  end
  
  
end
