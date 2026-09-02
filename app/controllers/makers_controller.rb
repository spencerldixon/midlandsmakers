# Signed-in maker management. load_and_authorize_resource does the scoping
# via Ability: admins get every maker, everyone else gets only their own
# (index, edit, update, destroy) and can create one of their own. Publishing
# is a two-step handshake — see #publish/#unpublish/#approve — kept separate
# from #update so the ability rules for each stay simple and explicit rather
# than parameter-sniffing inside a generic update.
class MakersController < ApplicationController
  load_and_authorize_resource
  before_action :set_assignable_users, only: [ :new, :edit, :create, :update ]
  before_action :redirect_if_already_owns_a_maker, only: [ :new, :create ]
  before_action :set_tag_options, only: [ :new, :edit, :create, :update ]

  def index
    @makers = @makers.order(:name)
  end

  def new
  end

  def create
    @maker.user = current_user unless current_user.admin?

    if @maker.save
      redirect_to makers_path, notice: "#{@maker.name} was added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @maker.update(maker_params)
      redirect_to makers_path, notice: "#{@maker.name} was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @maker.destroy
    redirect_to makers_path, notice: "#{@maker.name} was removed."
  end

  # Owner-facing: ask to go live. Never publishes directly — always drops
  # into pending_approval, even if this maker has been approved before.
  def publish
    @maker.pending_approval!
    redirect_to makers_path, notice: "#{@maker.name} was submitted for approval."
  end

  # Owner-facing: pull down immediately. No approval needed to go backwards.
  def unpublish
    @maker.unpublished!
    redirect_to makers_path, notice: "#{@maker.name} was unpublished."
  end

  # Admin-only (see Ability) — the only path that actually sets published,
  # i.e. the only path that makes a listing show up on the public directory.
  def approve
    @maker.published!
    redirect_to makers_path, notice: "#{@maker.name} is now live on the directory."
  end

  private

  # One listing per account. Without this a non-admin resubmitting "New
  # maker" would hit the DB's unique index on makers.user_id as a raw
  # constraint violation (500) rather than a friendly redirect.
  def redirect_if_already_owns_a_maker
    return if current_user.admin? || current_user.maker.blank?

    redirect_to edit_maker_path(current_user.maker), notice: "You already have a listing — editing it here."
  end

  # Anyone without a maker already, plus this maker's current owner (so
  # editing a maker doesn't drop them out of their own dropdown). Only
  # meaningful for admins — the form only renders this field for them.
  def set_assignable_users
    return unless current_user.admin?

    @assignable_users = User.where(id: [ *User.where.missing(:maker).select(:id), @maker.user_id ].compact)
                             .order(:email)
  end

  # Every tag already in use across the directory, so the picker can offer
  # them as a searchable list on top of letting you type a new one.
  def set_tag_options
    @tag_options = ActsAsTaggableOn::Tag.order(:name).pluck(:name)
  end

  def maker_params
    permitted = [ :name, :description, :website_url, :instagram_url, :image, tag_list: [] ]
    permitted << :user_id if current_user.admin?
    params.require(:maker).permit(*permitted)
  end
end
