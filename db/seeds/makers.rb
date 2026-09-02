require "open-uri"
require "fileutils"
require "vips"

# Local cache for downloaded maker photos, so re-seeding doesn't re-hit the
# network and the files can be committed for reproducible seeds.
IMAGE_CACHE_DIR = Rails.root.join("db/seeds/data/images")
FileUtils.mkdir_p(IMAGE_CACHE_DIR)

# Wix serves a small, artifact-heavy derivative at the URL stored in
# makers.yml (.../v1/fill/w_403,h_334,...,q_80,...,enc_avif,.../file.jpg).
# The unmodified original lives at the same path up to "~mv2.<ext>" — strip
# the resize/quality/encoding suffix to get it.
def original_wix_url(url)
  url.sub(/(~mv2\.\w+).*/i, '\1')
end

# A handful of the source PNGs carry a fully-opaque alpha channel (left over
# from how they were exported/screenshotted). Verified by testing all four
# combinations on the same file: when that alpha channel survives into
# image_processing's resize_to_fill (app/views/makers/_maker.html.erb) *and*
# its default post-resize sharpen convolution runs, the two interact to
# produce scattered colour-fringe artifacts around edges — disabling only
# one or the other still leaves the bug. Flattening here (removing alpha
# entirely, since it carries no real transparency) plus sharpen: nil at the
# variant call sites is what actually clears it. No-op for plain JPEGs.
def flatten_alpha(bytes)
  image = Vips::Image.new_from_buffer(bytes, "")
  return bytes unless image.has_alpha?

  image.flatten(background: [ 255, 255, 255 ]).write_to_buffer(".png")
end

source_url = "https://www.midlandsmakers.co.uk/makersdirectory"
makers = YAML.safe_load_file(Rails.root.join("db/seeds/makers.yml"), symbolize_names: true)

downloaded = 0
attached = 0
failed = []

makers.each do |attributes|
  # category isn't a real column any more (see Maker) — it only ever existed
  # to become tags, via CATEGORY_TAG_RULES below.
  category = attributes.fetch(:category)

  maker = Maker.find_or_initialize_by(name: attributes.fetch(:name))
  # Already-vetted directory content, not a user submission awaiting
  # moderation — publish outright rather than defaulting to unpublished
  # (matters on a fresh db:setup, where there's no existing row for the
  # AddStatusToMakers migration's one-time backfill to have already fixed).
  maker.update!(attributes.except(:category).merge(source_url: source_url, status: :published))
  maker.tag_list = Maker.category_tags_for(category)
  maker.save! if maker.tag_list_changed?

  next if maker.image.attached?

  begin
    full_size_url = original_wix_url(maker.image_url)
    extension = File.extname(URI.parse(full_size_url).path).presence || ".jpg"
    local_path = IMAGE_CACHE_DIR.join("#{maker.name.parameterize}#{extension}")

    unless local_path.exist?
      raw_bytes = URI.parse(full_size_url).open("rb", &:read)
      File.binwrite(local_path, flatten_alpha(raw_bytes))
      downloaded += 1
    end

    maker.image.attach(io: File.open(local_path), filename: local_path.basename.to_s)
    attached += 1
  rescue StandardError => e
    failed << "#{maker.name}: #{e.message}"
  end
end

puts "Seeded #{makers.size} Midlands makers (#{downloaded} images downloaded, #{attached} attached)"
warn "Could not process images for:\n  #{failed.join("\n  ")}" if failed.any?
