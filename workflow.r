pacman::p_load(dplyr,
               tidyr,
               purrr,
               gsheet,
               lubridate,
               rmarkdown)

# Read in the code for processing raw data
source("r/functions_and_lookups.r")


#File pathe to most recent archive
archive_path<-paste0("data/",tail(list.files("data"),1))



#The code to read the archive in is very straightforward
archive<-readr::read_rds(path = archive_path)

#List of new urls to process
new_urls<-list("https://docs.google.com/spreadsheets/d/1Aam2yf5hh_DvqoafmQlNIuztCn-nzbJnKiYR_g31tl0/edit?usp=sharing")
# You can call the process_survey function directly and supply a list of urls.
df<-process_survey(new_urls)

#Create filename for today's archive
todays_archive <- paste0("data/",Sys.Date(),"_archive.rds") # Create a string for the path to the archive file 

#Save new archive
readr::write_rds(archive,
                 path = todays_archive)


pdf_filename <- "../pdf/Report.pdf"# Create a string for the path to the archive file 

#Render the PDF
rmarkdown::render("rmd/wellbeing_report.rmd",
                  output_format = "pdf_document",
                  output_file = pdf_filename,
                  clean = TRUE)


