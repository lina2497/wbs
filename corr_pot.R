pacman::p_load(openair, tidyverse)

#File pathe to most recent archive
archive_path<-paste0("data/",tail(list.files("data"),1))

#The code to read the archive in is very straightforward
archive<-readr::read_rds(path = archive_path)


archive$data%>%
  select(time, question_number, score)%>%
  pivot_wider(names_from = question_number,
              values_from = score)%>%
openair::corPlot()
