
#pak::pak("francescojm/CRISPRcleanR")

ggplot2::theme_set(ggplot2::theme_light())

cache <- file.path("D:", "Promotion_cache", "GIN_CRISPRCleanR")

dir.create(cache, F, T)

.file <- file.path(cache, "fcGuides.rds")

if (!file.exists(.file)) {
  load(file.path("D:", "Promotion_project_data", "GIN_data", "CRISPRCleanR", "fcGuides.rda"))
  saveRDS(fcGuides, .file)
}


.file <- file.path(cache, "libAnno.rds")

if (!file.exists(.file)) {
  load(file.path("D:", "Promotion_project_data", "GIN_data", "CRISPRCleanR", "libAnno.rda"))
  saveRDS(libAnno, .file)
}

