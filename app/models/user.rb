class User < ApplicationRecord
  has_secure_password
  validates_uniqueness_of :username
  validates :password,   :length => { :minimum => 8}
  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  validates :email, uniqueness: true
  validates :email, presence: true
  validates :username, presence: true
end
