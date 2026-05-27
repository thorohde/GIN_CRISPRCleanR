
library(targets)

tar_option_set(
  packages = c("CRISPRcleanR", "data.table", "ggplot2", "purrr", "stringr"), 
  format = "rds")

tar_source("R/initialize.R")
tar_source("R/tar_functions.R")


list(
  tar_target(fcGuides, load_fcGuides()), 
  tar_target(libAnno, load_libAnno()), 
  tar_target(screens_oi, define_screens_of_interest(fcGuides)), 
  tar_target(CCR_input, create_CCR_input(fcGuides, libAnno, screens_oi)), 
  tar_target(CCR_chromPos, create_CCR_chromPos(CCR_input, libAnno)), 
  
  tar_target(CCR_GWclean_3_2, create_CCR_GWclean(CCR_chromPos, min.ngenes = 3, min.width = 2)), 
  tar_target(CCR_GWclean_50_2, create_CCR_GWclean(CCR_chromPos, min.ngenes = 50, min.width = 2)), 
  tar_target(CCR_stats_3_2, collect_CCR_stats(CCR_GWclean_3_2)), 
  tar_target(CCR_stats_50_2, collect_CCR_stats(CCR_GWclean_50_2)), 
  
  tar_target(p_chr15_plt_1, draw_chr15_plt(CCR_GWclean_3_2, which = "avgLFC", .fpath = file.path("plots", "chr15_avgLFC.png")), format = "file"), 
  tar_target(p_chr15_plt_2, draw_chr15_plt(CCR_GWclean_3_2, which = "correctedLFC", .fpath = file.path("plots", "chr15_correctedLFC.png")), format = "file")

)


