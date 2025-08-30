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
