class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :lockable, :confirmable, :trackable

  # A user's own listing in the directory, if an admin has linked one to
  # them. Left in place (not destroyed) if the account goes away, since the
  # maker is still a real, publicly-listed profile.
  has_one :maker, dependent: :nullify

  # Add terms and conditions validation on create
  attr_accessor :terms_and_conditions
  validates_acceptance_of :terms_and_conditions, allow_nil: false, on: :create

  validates :email, presence: true, 'valid_email_2/email': true
end
