#!/usr/bin/env ruby
# frozen_string_literal: true

require 'date'
require 'csv'
require 'optparse'

# Generates SVG calendar files with customizable layouts and monthly notes
class SVGCalendarGenerator
	# Day abbreviations for different week start preferences
	DAYS_OF_WEEK = {
		sunday: %w[S M T W T F S],
		monday: %w[M T W T F S S]
	}.freeze

	MONTH_NAMES = %w[
		JANUARY FEBRUARY MARCH APRIL MAY JUNE
		JULY AUGUST SEPTEMBER OCTOBER NOVEMBER DECEMBER
	].freeze

	# SVG canvas dimensions in pixels
	CANVAS_WIDTH = 1300
	CANVAS_HEIGHT = 800
	EXTRA_WEEK_HEIGHT = 80

	# Grid layout constants
	GRID_START_X = 60
	GRID_START_Y = 280
	CELL_WIDTH = 100
	CELL_HEIGHT = 80

	# Typography positioning
	MONTH_TITLE_Y = 80
	NOTE_START_Y = 120
	NOTE_LINE_HEIGHT = 30
	NOTE_CHAR_LIMIT = 255
	NOTE_WRAP_LENGTH = 80

	# Important dates section - RIGHT SIDE positioning
	IMPORTANT_DATES_X = 1000
	IMPORTANT_DATES_Y = GRID_START_Y - 20  # Same Y position as day headers
	IMPORTANT_DATES_START_Y = 320
	IMPORTANT_DATES_LINE_SPACING = 80
	IMPORTANT_DATES_TEXT_WIDTH = 160
	IMPORTANT_DATES_LINE_WIDTH = 300

	# Font file paths - put your font files in a 'fonts' directory
	FONT_DIR = './fonts'
	OPEN_SANS_FONT = "#{FONT_DIR}/OpenSans-SemiBold.woff2"
	PLAYFAIR_FONT = "#{FONT_DIR}/PlayfairDisplay-Regular.woff2"
	PLAYFAIR_BOLD_FONT = "#{FONT_DIR}/PlayfairDisplay-Bold.woff2"

	attr_reader :start_month, :start_year, :num_months, :week_start, :notes, :note_line_height

	# Initialize calendar generator with configuration options
	def initialize(options = {})
		@start_month = options[:start_month] || Date.today.month
		@start_year = options[:start_year] || Date.today.year
		@num_months = options[:num_months] || 1
		@week_start = options[:week_start] || :monday
		@notes_file = options[:notes_file]
		@note_line_height = options[:note_line_height] || NOTE_LINE_HEIGHT
		@notes = load_notes_from_csv if @notes_file
	end

	# Generate SVG calendars for specified number of months
	def generate
		calendars = []
		current_date = Date.new(start_year, start_month, 1)

		num_months.times do
			calendars << generate_single_month(current_date)
			current_date = current_date.next_month
		end

		calendars
	end

	private

	# Load monthly notes from CSV file
	def load_notes_from_csv
		return {} unless File.exist?(@notes_file)

		notes_hash = {}
		CSV.foreach(@notes_file, headers: true) do |row|
			begin
				# Parse the date from whatever format is in the CSV
				parsed_date = Date.parse(row['month'].to_s.strip)
				
				# Create a standardized key: "month year" (e.g., "march 2025")
				month_key = "#{MONTH_NAMES[parsed_date.month - 1].downcase} #{parsed_date.year}"
				
				note_text = row['note'].to_s[0...NOTE_CHAR_LIMIT]
				notes_hash[month_key] = note_text
				
				puts "Loaded note for: #{month_key}" if ENV['DEBUG']
			rescue Date::Error => e
				warn "Warning: Could not parse date '#{row['month']}': #{e.message}"
				next
			end
		end
		
		puts "Total notes loaded: #{notes_hash.size}" if ENV['DEBUG']
		notes_hash
	rescue CSV::MalformedCSVError => e
		warn "Warning: Error reading CSV file: #{e.message}"
		{}
	end

	# Retrieve note for specific month
	def find_note_for(date)
		return nil unless notes

		# Generate standardized key to match what we stored
		month_key = "#{MONTH_NAMES[date.month - 1].downcase} #{date.year}"
		note = notes[month_key]
		
		puts "Looking for: #{month_key} -> #{note ? 'Found' : 'Not found'}" if ENV['DEBUG']
		
		note
	end

	# Calculate number of week rows needed for month display
	def calculate_month_layout(date)
		first_day = date
		last_day = Date.new(date.year, date.month, -1)
		starting_weekday = calculate_starting_weekday(first_day)

		total_cells_needed = starting_weekday + last_day.day
		weeks_required = (total_cells_needed / 7.0).ceil

		{
			weeks: weeks_required,
			starting_weekday: starting_weekday,
			last_day: last_day
		}
	end

	# Calculate the starting weekday position based on week start preference
	def calculate_starting_weekday(date)
		if week_start == :monday
			date.wday.zero? ? 6 : date.wday - 1
		else
			date.wday
		end
	end

	def calculate_svg_height(weeks_count)
		weeks_count > 5 ? CANVAS_HEIGHT + EXTRA_WEEK_HEIGHT : CANVAS_HEIGHT
	end

	# Generate complete SVG for a single month
	def generate_single_month(date)
		month_name = MONTH_NAMES[date.month - 1]
		year = date.year
		note_text = find_note_for(date)
		layout = calculate_month_layout(date)

		svg_height = calculate_svg_height(layout[:weeks])

		svg_content = build_svg_document(
			month_name: month_name,
			note_text: note_text,
			date: date,
			layout: layout,
			height: svg_height
		)

		{
			filename: "calendar_#{month_name.downcase}_#{year}.svg",
			content: svg_content
		}
	end

	# Update the SVG to center the text
	def build_svg_document(month_name:, note_text:, date:, layout:, height:)
		svg_content = <<~SVG
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="#{CANVAS_WIDTH}" height="#{height}" viewBox="0 0 #{CANVAS_WIDTH} #{height}">
#{svg_styles}

		<!-- Month Title -->
		<text x="#{CANVAS_WIDTH / 2}" y="#{MONTH_TITLE_Y}" class="month-title" text-anchor="middle">#{month_name}</text>

#{build_note_section(note_text) if note_text}

		<!-- Calendar Grid -->
#{build_calendar_grid(date, layout)}

		<!-- Important Dates Section - Center-aligned text -->
		<text x="#{IMPORTANT_DATES_X}" y="#{IMPORTANT_DATES_Y}" class="important-header" text-anchor="middle">IMPORTANT DATES</text>
#{build_important_dates_lines}
</svg>
		SVG

		svg_content.strip
	end

	# Build horizontal lines for important dates section - Centered under text
	def build_important_dates_lines
		# Make short lines that fit nicely under the text
		half_width = IMPORTANT_DATES_LINE_WIDTH / 2

		lines = 5.times.map do |index|
			y_position = IMPORTANT_DATES_START_Y + (index * IMPORTANT_DATES_LINE_SPACING)
			x_start = IMPORTANT_DATES_X - half_width
			x_end = IMPORTANT_DATES_X + half_width

			%(<line x1="#{x_start}" y1="#{y_position}" x2="#{x_end}" y2="#{y_position}" class="important-line"/>)
		end

		lines.join("\n        ")
	end

	def svg_styles
		<<~STYLES
	    <defs>
	    	<style><![CDATA[
	    		.month-title { 
	    			font-family: 'Open Sans', 'Helvetica Neue', Arial, sans-serif; 
	    			font-weight: 600; 
	    			font-size: 72px; 
	    			fill: #D4A574; 
	    		}
	    		.month-note { 
	    			font-family: 'Playfair Display', Georgia, serif; 
	    			font-size: 24px; 
	    			fill: #333; 
	    			text-anchor: middle; 
	    		}
	    		.day-header { 
	    			font-family: 'Playfair Display', Georgia, serif; 
	    			font-size: 36px; 
	    			fill: #D4A574; 
	    			font-weight: bold; 
	    			text-anchor: middle;
	    		}
	    		.day-number { 
	    			font-family: 'Playfair Display', Georgia, serif; 
	    			font-size: 48px; 
	    			fill: #333; 
	    			text-anchor: middle;
	    		}
	    		.important-header { 
	    			font-family: 'Playfair Display', Georgia, serif; 
	    			font-size: 36px; 
	    			fill: #D4A574; 
	    		}
	    		.important-line { 
	    			stroke: #333; 
	    			stroke-width: 1; 
	    		}
	    	]]></style>
	    </defs>
		STYLES
	end

	# Build note section with configurable line spacing
	def build_note_section(note_text)
		wrapped_lines = word_wrap(note_text, NOTE_WRAP_LENGTH)
		
		# Limit to maximum 3 lines to prevent overlap
		wrapped_lines = wrapped_lines.first(3)

		text_elements = wrapped_lines.map.with_index do |line, index|
			y_position = NOTE_START_Y + (index * note_line_height)
			%(<text x="#{CANVAS_WIDTH / 2}" y="#{y_position}" class="month-note">#{line}</text>)
		end

		text_elements.join("\n        ")
	end

	# Word wrap text with better sentence handling
	def word_wrap(text, max_length)
		# Split into sentences first for better breaking
		sentences = text.split(/[.!?]+/).map(&:strip).reject(&:empty?)
		
		if sentences.length > 1
			# If multiple sentences, try to keep them intact
			lines = []
			current_line = ""
			
			sentences.each do |sentence|
				sentence += "." unless sentence.end_with?('.', '!', '?')
				
				if current_line.empty?
					current_line = sentence
				elsif (current_line + " " + sentence).length <= max_length
					current_line += " " + sentence
				else
					lines << current_line
					current_line = sentence
				end
			end
			
			lines << current_line unless current_line.empty?
			return lines
		end
		
		# Fall back to word wrapping for single sentences
		words = text.split(' ')
		lines = []
		current_line = []

		words.each do |word|
			test_line = (current_line + [word]).join(' ')
			if test_line.length > max_length && current_line.any?
				lines << current_line.join(' ')
				current_line = [word]
			else
				current_line << word
			end
		end

		lines << current_line.join(' ') if current_line.any?
		lines
	end

	# Build calendar grid with day numbers
	def build_calendar_grid(date, layout)
		elements = []

		# Add day of week headers
		elements.concat(build_weekday_headers)

		# Add day numbers
		elements.concat(build_day_numbers(layout))

		elements.join("\n        ")
	end

	# Build weekday header row
	def build_weekday_headers
		DAYS_OF_WEEK[week_start].map.with_index do |day_abbr, index|
			x_position = GRID_START_X + (index * CELL_WIDTH) + (CELL_WIDTH / 2)
			y_position = GRID_START_Y - 20
			%(<text x="#{x_position}" y="#{y_position}" class="day-header">#{day_abbr}</text>)
		end
	end

	# Build day number grid
	def build_day_numbers(layout)
		elements = []
		current_day = 1

		layout[:weeks].times do |week_index|
			7.times do |day_index|
				cell_position = week_index * 7 + day_index

				if cell_position >= layout[:starting_weekday] && current_day <= layout[:last_day].day
					x_position = GRID_START_X + (day_index * CELL_WIDTH) + (CELL_WIDTH / 2)
					y_position = GRID_START_Y + (week_index * CELL_HEIGHT) + 40

					elements << %(<text x="#{x_position}" y="#{y_position}" class="day-number">#{current_day}</text>)
					current_day += 1
				end
			end

			break if current_day > layout[:last_day].day
		end

		elements
	end
end

# Parse command line arguments
def parse_options
	options = {
		num_months: 1,
		week_start: :monday,
		start_month: Date.today.month,
		start_year: Date.today.year,
		note_line_height: SVGCalendarGenerator::NOTE_LINE_HEIGHT
	}

	parser = OptionParser.new do |opts|
		opts.banner = "Usage: svg_calendar.rb [options]"

		opts.on("-n", "--num-months NUM", Integer, "Number of months to generate (default: 1)") do |n|
			options[:num_months] = n
		end

		opts.on("-w", "--week-start DAY", [:monday, :sunday],
			"Week start day (monday/sunday, default: monday)") do |w|
				options[:week_start] = w
			end

		opts.on("-m", "--start-month MONTH", Integer,
			"Starting month (1-12, default: current month)") do |m|
				if m.between?(1, 12)
					options[:start_month] = m
				else
					warn "Warning: Invalid month #{m}, using current month"
				end
			end

		opts.on("-y", "--start-year YEAR", Integer,
			"Starting year (default: current year)") do |y|
				options[:start_year] = y
			end

		opts.on("-f", "--notes-file FILE", "CSV file with monthly notes") do |f|
			options[:notes_file] = f
		end

		opts.on("-l", "--line-height HEIGHT", Integer, "Note line height spacing (default: 35)") do |l|
			options[:note_line_height] = l
		end

		opts.on("-h", "--help", "Show this help message") do
			puts opts
			exit
		end
	end

	parser.parse!
	options
rescue OptionParser::InvalidOption => e
	warn "Error: #{e.message}"
	warn "Use -h for help"
	exit 1
end

# Display generation summary
def display_summary(calendars, options)
	puts "\nCalendar Details:"

	calendars.each do |calendar|
		next unless calendar[:filename] =~ /calendar_(\w+)_(\d+)\.svg/

		month_name = $1.capitalize
		year = $2
		date = Date.parse("#{month_name} 1, #{year}")

		generator = SVGCalendarGenerator.new(options)
		layout = generator.send(:calculate_month_layout, date)

		puts "  #{month_name} #{year}: #{layout[:weeks]} weeks " \
			"(#{layout[:last_day].day} days, starts on position #{layout[:starting_weekday]})"
	end
end

# Main execution
if __FILE__ == $0
	options = parse_options
	generator = SVGCalendarGenerator.new(options)
	calendars = generator.generate

	# Save generated files
	calendars.each do |calendar|
		File.write(calendar[:filename], calendar[:content])
		puts "Generated: #{calendar[:filename]}"
	end

	puts "\nCalendar generation complete!"
	display_summary(calendars, options)
end
