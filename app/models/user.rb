class User < ApplicationRecord
  has_secure_password
  validates_uniqueness_of :username, :email
  validates :password,   :length => { :minimum => 8}

end
