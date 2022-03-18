class UsermailerMailer < ApplicationMailer
  default from: 'noreply@10athletes.com'

   def welcome_email(user)
      @user = user
      @url  = 'http://www.10athletes.com'
      mail(to: @user.email, subject: 'Welcome to 10Athletes')
   end
end
