library("data.table")
library("readr")
# load r packages so they are cited
devtools::load_all()
# relative project path to the .Rmd files
path = "./"
# name of the file where to write the references to
out.file = "11-references.Rmd"

# Function to collect list of .Rmd files
get_file_list = function(folder){
  paste(folder, list.files(folder, pattern = ".Rmd"), sep = "/")
}

# Function to create a list of references from list of .Rmd
grep_references = function(file){
  # read in file as string
  lines = readr::read_lines(file)
  # grep lines starting with[^XXX]:
  lines = lines[grep("\\[\\^[a-z;A-Z;0-9;\\-]*\\]\\:", lines)]
  # split by first :
  splitted = strsplit(lines, "]: ")
  # store in data.frame with key and ref
  res = data.table::rbindlist(lapply(splitted,
    function(x) data.frame(t(x), stringsAsFactors = FALSE)))
  if ( nrow(res) > 0) {
    colnames(res) = c("key", "reference")
    res$key = gsub("\\[\\^", "", res$key)
  }
  res
}


# Adapted from knitr::write_bib
# For the citation of the R packages
get_R_bib = function (tweak = TRUE, width = NULL){
  lib = packageDescription("iml.book")
  x = unlist(strsplit(lib$Import, ",\\n"))
#   x = c(x, "knitr")
  bib = sapply(x, function(pkg) {
    cite = citation(pkg, auto = if (pkg == "base")
      NULL
      else TRUE)
    if (tweak) {
      cite$title = gsub(sprintf("^(%s: )(\\1)", pkg), "\\1",
        cite$title)
      cite$title = gsub(" & ", " \\\\& ", cite$title)
    }
    cite
  },
  simplify = FALSE)
  bib = bib[sort(x)]
  invisible(bib)
}




file_list = get_file_list(path)
file_list = setdiff(file_list, paste(path, "interpretable-ml.Rmd", sep = "/"))
reference_list = data.table::rbindlist(lapply(file_list, grep_references),
				       fill = TRUE)

reference_list = unique(reference_list)
reference_list = reference_list[order(reference_list$reference), ]

r_reference_list = get_R_bib()

fileConn <- file(paste(path, out.file, sep = "/"))
write_string = c("# References {-}",
  "<!-- Generated automatically, please don't edit manually! -->")
for ( i in 1:nrow(reference_list)) {
  write_string = c(write_string, "", reference_list$reference[i])
}
write_string = c(write_string, "",  "## R Packages Used {-}", "")
for ( i in 1:length(r_reference_list)) {
  r_package_citation = paste0("**", names(r_reference_list[i]), "**. ",
    base::format(r_reference_list[[i]], "text"))
  write_string = c(write_string, "", r_package_citation)
}
write_lines(write_string, fileConn)
