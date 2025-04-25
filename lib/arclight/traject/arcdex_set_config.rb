require "logger"
require "traject"
require "traject_plus"
require "traject_plus/macros"
require "json"
require "arclight/traject/json_reader"
require "debug"

extend TrajectPlus::Macros

settings do
  provide "reader_class_name", "Arclight::Traject::JsonReader"
  provide "processing_collections", true
  provide "solr_writer.commit_on_close", "true"
  provide "logger", Logger.new($stderr)
end

# ID field (prefix with 'set_' to distinguish)
to_field "id", lambda { |record, accumulator| accumulator << record["id"] }

# Set collection fields
to_field "title_ssm", lambda { |record, accumulator| accumulator << record["name"] }
to_field "title_tesim", lambda { |record, accumulator| accumulator << record["name"] }
to_field "normalized_title_ssm", lambda { |record, accumulator| accumulator << record["name"] }

# Set this as a collection-level record
to_field "level_ssm", lambda { |_record, accumulator| accumulator << "set" }
to_field "level_ssim", lambda { |_record, accumulator| accumulator << "Set" }

to_field "series_ssm", lambda { |record, accumulator| accumulator << record["series"] if record["series"] }

to_field "printed_total_isi", lambda { |record, accumulator| accumulator << record["printedTotal"].to_i if record["printedTotal"] }

to_field "total_items_isi", lambda { |record, accumulator| accumulator << record["total"].to_i if record["total"] }

to_field "legalities_json_ssi" do |record, accumulator|
  if record["legalities"]
    accumulator << record["legalities"].to_json
  end
end
to_field "legalities_ssm" do |record, accumulator|
  if record["legalities"]
    record["legalities"].each do |format, status|
      accumulator << "#{format}: #{status}"
    end
  end
end

to_field "ptcgo_code_ssi", lambda { |record, accumulator| accumulator << record["ptcgoCode"] if record["ptcgoCode"] }

to_field "release_date_ssm" do |record, accumulator|
  if record["releaseDate"]
    # Convert from 1999/01/09 to 1999-01-09 format
    formatted_date = record["releaseDate"].gsub("/", "-")
    accumulator << formatted_date
  end
end
to_field "release_date_sort" do |record, accumulator|
  if record["releaseDate"]
    # Keep the format YYYY/MM/DD which sorts correctly as strings
    accumulator << record["releaseDate"]
  end
end

to_field "updated_at_ssm" do |record, accumulator|
  accumulator << record["updatedAt"] if record["updatedAt"]
end
to_field "updated_at_sort" do |record, accumulator|
  if record["updatedAt"]
    # Convert from "2022/10/10 15:12:00" to "2022-10-10T15:12:00"
    formatted_datetime = record["updatedAt"].gsub("/", "-").gsub(" ", "T")
    accumulator << formatted_datetime
  end
end

to_field "images_json_ssi" do |record, accumulator|
  if record["images"]
    accumulator << record["images"].to_json
  end
end
to_field "symbol_url_ssm" do |record, accumulator|
  if record["images"] && record["images"]["symbol"]
    accumulator << record["images"]["symbol"]
  end
end
to_field "logo_url_ssm" do |record, accumulator|
  if record["images"] && record["images"]["logo"]
    accumulator << record["images"]["logo"]
  end
end
