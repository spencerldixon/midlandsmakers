# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user.present?

    if user.admin?
      can :manage, :all
    else
      # Unconditional on create: the object being authorized has no user_id
      # yet at this point (MakersController sets it after authorization, and
      # strong params never let a non-admin submit one), so a user_id: hash
      # condition here would just fail every create. Ownership is enforced
      # procedurally in the controller instead.
      can :create, Maker
      can [ :read, :update, :destroy, :publish, :unpublish ], Maker, user_id: user.id

      # :approve is deliberately absent — only an admin (can :manage, :all,
      # above) can move a listing to "published". An owner can ask to
      # publish (-> pending_approval) and unpublish their own at will, but
      # can never grant themselves the live status directly.
    end
  end
end
