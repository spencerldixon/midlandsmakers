class AddStatusToMakers < ActiveRecord::Migration[8.1]
  def up
    add_column :makers, :status, :integer, default: 0, null: false
    add_index :makers, :status

    # Existing rows (the original seed import, plus anything created before
    # this migration) are already-vetted directory content, not a user
    # submission awaiting moderation — mark them live rather than dropping
    # every one of them out of the public directory pending approval.
    execute "UPDATE makers SET status = 2"
  end

  def down
    remove_index :makers, :status
    remove_column :makers, :status
  end
end
