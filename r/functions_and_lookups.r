
question_lookup<-function(){
  
  # This is a little lookup table which we use to label the questions with their
  # appropriate number. Written this way it is easy to change the order of the
  # questions if we decide to.
  # The function takes no arguments and returns a tibble.
  
  
  question_lookup <- list(
    q1 = "In the last week how would you rate your overall wellbeing/mental health?",
    q1_2 = "Is there anything we can do to help support your overall wellbeing/mental health?",
    q2 = "In the last week how would you rate your work/life balance?",
    q3 = "In the last week how would you rate your workload?",
    q4 = "In the last week how included/valued/supported have you felt at work?",
    q4_1 = "In the last week how included have you felt at work?",
    q4_2 = "In the last week how valued have you felt at work?",
    q4_3 = "In the last week how supported have you felt at work?",
    q5 = "In the last week how would you rate your working environment?",
    q6 = "How satisfied or dissatisfied are you with your present job overall?",
    q7 = "Is there anything in particular you want to tell us?"
  ) %>%
    tibble::as_tibble() %>%
    tidyr::pivot_longer(everything(), names_to = "question_number", values_to = "question_name")
}

new_url<- list(
  "https://docs.google.com/spreadsheets/d/1Aam2yf5hh_DvqoafmQlNIuztCn-nzbJnKiYR_g31tl0/edit?usp=sharing",
  "https://docs.google.com/spreadsheets/d/1ujKH0FIz04lzD-kBphK2Vsv82iksvKMcWUB8l4nJbAA/edit?usp=sharing",
  "https://docs.google.com/spreadsheets/d/1LAXQzcCV8uho2wzmV8MZT4UmamtfrvzzEkb970FSu7w/edit?usp=sharing"
  
)
process_survey<-function(new_url, archive=FALSE){
  
  # This function fetches the survey results from their urls, tidies them and 
  # returns a tibble with the processed results. You must supply this fucntion
  # with at least one url, stored in a list(), or it will fail. You may also
  # supply an archive of already processed data to combine wiht the new results.

  # new_url (list) A list of survey results url strings
  # archive (list) A list with 2 elements:
  #                   data: a tibble containing the results of surveys which have
  #                         already been processed
  #                   urls: the urls of those surveys which have already been
  #                         processed.
  
  archive_found<-is.list(archive) #Has an archive been supplied?
  
  if(dplyr::n_distinct(new_url)!=length(new_url)){
    # if new_url contains duplicate urls, remove them.
    cli::cli_alert_warning("The list of new urls contains duplicates, they have been removed.")  
    new_url <-unique(new_url)
  }
  
  if (archive_found) {
    if (any(new_url %in% archive$urls)) {
      # If an archive has been supplied and any of the new urls have already been processed, remove them.
      cli::cli_alert_info(
        "At least one of the supplied urls is listed as having already been processed. It is being excluded."
      )
      new_url <- new_url[!(new_url %in% archive$urls)]
    }
    
    if (is_empty(new_url)) {
      # If after removing the duplicates there are no new urls left, stop and 
      # return just the archived data.
      cli::cli_alert("No new urls found, returning archived data.")
      return(archive$data)
    }
  }
  
  if(!(purrr::is_empty(new_url))){# If there are still some urls to process
    
    
    # if there is an archive, count the number of surveys and calculate which
    # survey number these new urls are.
    if(archive_found){
      survey_min_number = (length(archive$urls)+1)
      survey_max_number = survey_min_number+length(new_url)-1
      survey_numbers =as.character(survey_min_number:survey_max_number)
    }
    
    # If there is no archive, number the surveys by the order supplied.
    if(!archive_found){
      survey_numbers = as.character(1:length(new_url))
    }
    
    results <- new_url %>%
      purrr::set_names(survey_numbers) %>%  ### This sets the names of the elements of that list to the week of the survey
      purrr::map2_df(.,
                     names(.),
                     ~ gsheet::gsheet2tbl(.x) %>% ### This takes that list and reads all the elements into a single dataframe
                       dplyr::mutate(survey_number = .y))  ### With a single column added for the week of the survey from the supplied names
      
    
    pivot_specific <- function(data, team=FALSE) {
      # this is a little function which will handle the dataframes differently depending on the presence or absence of a team column
      
      
      if(team){out<-data %>%
        tidyr::pivot_longer(
          # This combines all of the questions into a single column
          cols = c(-survey_number,-Timestamp,-team),
          names_to = "question_name",
          values_to = "response"
        )}
      
      if(!team){out<-data %>%
        tidyr::pivot_longer(
          # This combines all of the questions into a single column
          cols = c(-survey_number,-Timestamp),
          names_to = "question_name",
          values_to = "response"
        )}
      return(out)
      
    }
    


  
team_column <- "Please select your team"%in%colnames(results) # detects team column

if(team_column){
  long_results<-rename(results, team = "Please select your team")%>%
    pivot_specific(team = T)
}
if(!team_column){
  long_results<-pivot_specific(results, team = F)
}

    results<-long_results%>%
      dplyr::mutate(
        survey_number = as.numeric(survey_number),
        #Turns the week into a number
        Timestamp = lubridate::mdy_hms(Timestamp)
      ) %>% # turns the timestamp into a date
      dplyr::left_join(question_lookup()) %>% # Adds int he question number
      dplyr::rename(time = Timestamp) # Tidyverse style guide reccomends lowercase variable names
    
    
    # Creates a little lookup of dates so that each survey has a specific date assigned to it
    # It also uses that date to assign a month date (first of the month) which will be useful for calculateing monthly scores.
    date_lookup <- results %>%
      dplyr::group_by(survey_number) %>%
      dplyr::summarise(survey_date = lubridate::date(min(time)), # assign the date of the survey to the earliest response
                       survey_month = lubridate::ymd(paste( # use the date to calculate the month of the survey
                         lubridate::year(survey_date),
                         lubridate::month(survey_date),
                         "01",
                         sep = "_"
                       )))
    
    tidy_results <- dplyr::left_join(results, date_lookup)%>% #Here we add in the dates and convert the responses to scores.
      dplyr::mutate(score = case_when(response %in% c("Very good",	"Far too little",	"Very well", "Very satisfied") ~ 5,
                                      response %in% c("Somewhat good",	"Not quite enough",	"Moderately well", "Somewhat satisfied") ~ 4,
                                      response %in% c("Neither good or bad",	"Just the right balance",	"Neither good or bad", "Neither satisfied or dissatisfied") ~ 3,
                                      response %in% c("Somewhat bad",	"A bit too much",	"Not very", "Somewhat dissatisfied") ~ 2,
                                      response %in% c("Very bad",	"Far too much",	"Not at all", "Very dissatisfied") ~ 1))
  }
  
  # If there is an archive, combine the new results with those in the archive.
  if(archive_found){
    tidy_results<-list(urls = append(archive$urls,new_url),
                       data = dplyr::bind_rows(archive$data,tidy_results))
  }
  
  if(!archive_found){
    tidy_results<-list(urls = new_url,
                        data = tidy_results)
  }
  
  return(tidy_results)
  
}


