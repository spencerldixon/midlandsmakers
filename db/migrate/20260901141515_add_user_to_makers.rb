class AddUserToMakers < ActiveRecord::Migration[8.1]
  def change
    add_reference :makers, :user, null: true, foreign_key: true, index: { unique: true }

    # These were only ever populated by the original Wix-scrape seed data
    # (image_url is the source photo to download; source_url is the original
    # directory listing page). Makers created from the app itself — via the
    # new admin dashboard — upload an image directly and have no such source.
    change_column_null :makers, :image_url, true
    change_column_null :makers, :source_url, true
  end
end
