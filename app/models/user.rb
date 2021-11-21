class User < ApplicationRecord
  has_secure_password
  validates_uniqueness_of :username
  validates_uniqueness_of :email
  validates :password,   :length => { :minimum => 8}, :if => :password
end
