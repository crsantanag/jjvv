class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  enum :role,
        [ :normal,
          :admin ]

  has_many :addresses, dependent: :destroy
  has_many :apartments, dependent: :destroy
  has_many :deposits, dependent: :destroy
  has_many :bills, dependent: :destroy
end
