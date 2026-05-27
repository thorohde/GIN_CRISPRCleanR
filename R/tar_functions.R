

load_fcGuides <- \(.fpath = file.path(cache, "fcGuides.rds")) {
  output <- readRDS(.fpath)
  return(output)
}


load_libAnno <- \(.fpath = file.path(cache, "libAnno.rds")) {
  
  output <- readRDS(.fpath)
  setDT(output)
  
  output <- data.frame(
    output[, .(
      CODE = str_c(GENE, "_guide_", 1:.N), 
      GENES = GENE, 
      EXONE = NA, 
      CHRM = gsub("chr", "", CHROMOSOME), 
      STRAND, 
      STARTpos = START, 
      ENDpos = STOP, 
      seq = SEQUENCE), by = GENE])
  
  rownames(output) <- output[["CODE"]]
  
  return(output)
}


define_screens_of_interest <- \(fcGuides, 
                                skip = c("USP10_013_min", "PTAR1_043_min") # these screens cause problems
                                ) {
  output <- c("WT_022_min", "WDR73_125_min")
  # output <- colnames(fcGuides)[1:50])
  if (!is.null(skip)) {output <- setdiff(output, skip)}
  
  return(output)
}



create_CCR_input <- \(fcGuides, libAnno, screens_oi) {
  
  output <- screens_oi |>
    set_names() |>
    map(~ data.frame(sgRNA = libAnno[, "CODE"], gene = rownames(fcGuides), fc = fcGuides[,.x])) |>
    imap(~ {setnames(.x, old = "fc", new = .y, skip_absent = T)})
  
  return(output)
}


create_CCR_chromPos <- \(CCR_input, libAnno) {
  
  output <- CCR_input |> map(~ ccr.logFCs2chromPos(foldchanges = .x, 
                                                   libraryAnnotation = libAnno))
  
  return(output)
}


create_CCR_GWclean <- \(CCR_chromPos, min.ngenes, min.width) {
  
  output <- CCR_chromPos |>
    imap(~ ccr.GWclean(
      gwSortedFCs = .x, 
      display = F, 
      label = .y, 
      min.ngenes = min.ngenes,  
      # minimal number of different genes that the set of sgRNAs within a region of estimated 
      # equal logFCs should target in order for their logFCs to be corrected
      min.width = min.width, 
      # 1:5, minimum number of markers for a changed segment. Maximum possible value is set at 5.
      verbose = 0))
  
  for (.n in names(output)) {
    setDT(output[[.n]]$segments)
    setDT(output[[.n]]$corrected_logFCs)
  }
  
  return(output)
}

collect_CCR_stats <- \(CCR_result) {
  

  
  output <- CCR_result |>
    map("corrected_logFCs") |>
    imap(~ {.x[, .(screen = .y, 
                   reduced = sum(correction == -1, na.rm = T), 
                   increased = sum(correction == 1, na.rm = T), 
                   changed = sum(correction %in% c(-1, 1), na.rm = T), 
                   not_changed = sum(correction == 0, na.rm = T))]
    })
  
  return(output)
}




draw_chr15_plt <- \(CCR_GWclean, cell_line = "WT_022_min", which = "avgLFC", .fpath) {
  
  dir.create(dirname(.fpath), F, T)
  
  if (which == "avgLFC") {
    .d <- CCR_GWclean[[cell_line]]$segments[CHR == 15]
  }
  
  if (which == "correctedLFC") {
    .d <- CCR_GWclean[[cell_line]]$corrected_logFCs[CHR == 15]
  }
  
  
  .plt <- ggplot(.d) + 
    geom_rect(mapping = aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax), 
              data = data.table(xmin = 61105000, xmax = 89890000, ymin = -2, ymax = 2), 
              alpha = 0.4, fill = "orange")
  
  if (which == "avgLFC") {
    .plt <- .plt + geom_segment(aes(x = startp, xend = endp, y = avg.logFC))
  }
  if (which == "correctedLFC") {
    .plt <- .plt + geom_point(aes(x = startp, y = avgFC - correctedFC))
  }
  
  .plt <- .plt + 
    scale_y_continuous(limits = c(-3, 3)) + 
    labs(title = "Chromosome 15", 
         subtitle = c("avgLFC" = "average logFC", "correctedLFC" = "corrected LFC")[[which]], 
         caption = cell_line)
  
  plot(.plt)
  
  ggsave(.fpath, plot = .plt, width = 7, height = 6, dpi = 300)
  
  return(.fpath)
}

