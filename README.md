# How to use

1. Open terminal app
2. Open the `aip_calendar` directory e.g. `cd aip_calendar`

The notes.csv file can be populated with the note for each given month, and includes
example content.

e.g.
month,note
January 2025,New year brings fresh opportunities and renewed energy for growth.
February 2025,Love and connection take center stage this month of warmth.
March 2025,Spring arrives with daffodils blooming and nature awakening.

# Command examples 

| Option | Long Form | Description | Default | Example |
|--------|-----------|-------------|---------|---------|
| `-n NUM` | `--num-months NUM` | Number of months to generate | 1 | `-n 12` |
| `-m MONTH` | `--start-month MONTH` | Starting month (1-12) | Current month | `-m 3` |
| `-y YEAR` | `--start-year YEAR` | Starting year | Current year | `-y 2025` |
| `-w DAY` | `--week-start DAY` | Week start (monday/sunday) | monday | `-w sunday` |
| `-f FILE` | `--notes-file FILE` | CSV file with monthly notes | None | `-f notes.csv` |
| `-l HEIGHT` | `--line-height HEIGHT` | Note line spacing in pixels | 30 | `-l 40` |
| `-h` | `--help` | Show help message | - | `-h` |

# Fonts
 
Double click these files in a fonts/ directory to add them to MacOS.

OpenSans-SemiBold.woff2
PlayfairDisplay-Regular.woff2
PlayfairDisplay-Bold.woff2

# Examples

## Generate current month
ruby calendar.rb

## Generate a full year
ruby calendar.rb -m 1 -y 2025 -n 12

## Generate with monthly notes
ruby calendar.rb -m 3 -y 2025 -n 3 -f notes.csv

## Edit variables to change fonts line spacing etc

Look inside the `calendar.rb` file and change as needed.

# SVG canvas dimensions in pixels
CANVAS_WIDTH = 1300
CANVAS_HEIGHT = 800
EXTRA_WEEK_HEIGHT = 80

# Grid layout
GRID_START_X = 60
GRID_START_Y = 280
CELL_WIDTH = 100
CELL_HEIGHT = 80

# Typography
MONTH_TITLE_Y = 80
NOTE_START_Y = 120
NOTE_LINE_HEIGHT = 30
NOTE_CHAR_LIMIT = 255
NOTE_WRAP_LENGTH = 80

# Important dates section
IMPORTANT_DATES_X = 1000
IMPORTANT_DATES_Y = GRID_START_Y - 20
IMPORTANT_DATES_START_Y = 320
IMPORTANT_DATES_LINE_SPACING = 80
IMPORTANT_DATES_TEXT_WIDTH = 160
IMPORTANT_DATES_LINE_WIDTH = 300

# Font sizes
MONTH_TITLE_FONT_SIZE = 80
DAY_HEADER_FONT_SIZE = 32
DAY_NUMBER_FONT_SIZE = 32
MONTH_NOTE_FONT_SIZE = 22
IMPORTANT_HEADER_FONT_SIZE = 40

