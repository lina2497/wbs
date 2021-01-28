pacman::p_load(dplyr,
               tidyr,
               purrr,
               gsheet,
               lubridate)

# Read in the code for processing raw data
source("r/functions_and_lookups.r")

#####________________________________________________________________________________________________________


# List of survey urls to create an archive with.
old_urls<-list(
  "https://docs.google.com/spreadsheets/d/1Uzx-gCK3fmDFnk5x9HA7nZetpuR7xCePHwWjyG1sXeE/edit?usp=sharing",
  "https://docs.google.com/spreadsheets/d/1vVb1-kPjfAwyJCqSPQYJ4T3teLnMYZnuQPpKmAgH-5g/edit?usp=sharing",
  "https://docs.google.com/spreadsheets/d/1KUbFDhrvEC0XMeKw5greLc6hWuLh6y09QQy00gqLoBI/edit?usp=sharing",
  "https://docs.google.com/spreadsheets/d/1dJol2RIVCWIdZx3aGY8U3cYcackoiUiCah_qNyJVqo0/edit?usp=sharing",
  "https://docs.google.com/spreadsheets/d/1uvheTjj6mxqI8RlgZmenItcmpAmpI6SVrVnJdFjOl48/edit?usp=sharing",
  "https://docs.google.com/spreadsheets/d/1BW2woreTTmfJbi9zFX-5d6UOMR2qabEIZal3CMFqGJk/edit?usp=sharing",
  "https://docs.google.com/spreadsheets/d/1ORywdYvX5K5oPkpjtpyA7nh1NfWdQU_0powRGi7Wd0s/edit?usp=sharing",
  "https://docs.google.com/spreadsheets/d/1DQmLe5wtAJDSwqKPaSERdwGgBAnVSEiUbDgcC1Xw33s/edit?usp=sharing",
  "https://docs.google.com/spreadsheets/d/15uqAiPX1reeoyBLg8CNdjCKgrK5hFY6z9odwh8lJ-hM/edit?usp=sharing"
)


#####________________________________________________________________________________________________________
# CREATING AN ARCHIVE FOR THE FIRST TIME


# If you run the create archive function and supply a list of urls, it will return a tidy dataframe of results
# and stor the list of input urls in the same list.

archive<-process_survey(old_urls)

# To save the list you can write it as an rds file

filename <- paste0("data/",Sys.Date(),"_archive.rds") # Create a string for the path to the archive file 

readr::write_rds(archive,
                 path = filename)

#The code to read the archive in is very straightforward
read_in_archive<-readr::read_rds(path = filename)
#####________________________________________________________________________________________________________
# PROCESSING NEW URLS

new_urls<-list("https://docs.google.com/spreadsheets/d/1Aam2yf5hh_DvqoafmQlNIuztCn-nzbJnKiYR_g31tl0/edit?usp=sharing")

# You can call the process_survey function directly and supply a list of urls.

df<-process_survey(new_urls)


#####________________________________________________________________________________________________________
# ROBUSTNESS

# The function is robust to duplicate urls and urls that have already been added to an archive.

duplicate_urls<-list("https://docs.google.com/spreadsheets/d/1Aam2yf5hh_DvqoafmQlNIuztCn-nzbJnKiYR_g31tl0/edit?usp=sharing",
                     "https://docs.google.com/spreadsheets/d/1Aam2yf5hh_DvqoafmQlNIuztCn-nzbJnKiYR_g31tl0/edit?usp=sharing",
                     "https://docs.google.com/spreadsheets/d/1Aam2yf5hh_DvqoafmQlNIuztCn-nzbJnKiYR_g31tl0/edit?usp=sharing",
                     "https://docs.google.com/spreadsheets/d/1Aam2yf5hh_DvqoafmQlNIuztCn-nzbJnKiYR_g31tl0/edit?usp=sharing",
                     "https://docs.google.com/spreadsheets/d/15uqAiPX1reeoyBLg8CNdjCKgrK5hFY6z9odwh8lJ-hM/edit?usp=sharing")

# Duplicates will be removed automatically.
process_survey(duplicate_urls)

# If you provide an arhive to the function as it's second argument, it will check the list of urls
# and combine the results.
process_survey(old_urls,read_in_archive)



