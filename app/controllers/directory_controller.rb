class DirectoryController < ApplicationController
  skip_before_action :authenticate_user!
  layout "directory"

  def index
    @query = params[:q].to_s.strip

    published_makers = Maker.published
    @available_tags = published_makers.tag_counts_on(:tags).order(:name)
    allowed_tags = @available_tags.map(&:name)
    @selected_tags = Array(params[:tags]).filter_map do |tag|
      tag.to_s.strip.presence
    end.uniq & allowed_tags

    @total_makers = published_makers.count
    @recent_makers = published_makers.joins(:image_attachment).order(created_at: :desc).limit(5)

    @makers = published_makers.full_text_search(@query)
    @makers = @makers.tagged_with(@selected_tags, on: :tags) if @selected_tags.any?
    @makers = @makers.order(:name) if @query.blank?
    @makers = @makers.includes(:tags)

    @meta_description = meta_description_for(@query, @selected_tags, @total_makers)
  end

  private

  # A search/filter still gets a meaningful og:description if shared, even
  # though the canonical tag (shared/_meta_tags.html.erb) always points
  # crawlers back at the unfiltered directory.
  def meta_description_for(query, tags, total)
    if query.present?
      %(Makers matching "#{query}" in the Midlands Makers directory.)
    elsif tags.any?
      "#{tags.to_sentence} makers in the Midlands Makers directory, covering independent artists, designers and craftspeople from across the Midlands, UK."
    else
      "The Midlands Makers directory — #{total} independent artists, designers and craftspeople from across the Midlands, UK. Browse by craft, get in touch directly."
    end
  end
end
