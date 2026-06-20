#!/usr/bin/env Rscript
# Maintainer: Jaewoong Lee <jaewoong@unist.ac.kr>
# Purpose:
#   Back up installed R package versions before an OS or R reinstall.
# Usage:
#   utility/r-freeze.R [OUTPUT_DIR]

args <- commandArgs(trailingOnly = TRUE)

show_help <- function() {
  cat(
    "Usage:\n",
    "  utility/r-freeze.R [OUTPUT_DIR]\n\n",
    "Back up the active R environment into OUTPUT_DIR.\n\n",
    "Artifacts:\n",
    "  renv.lock        Versioned lockfile for reproducible restore\n",
    "  requirements.txt Pip-style Package==Version fallback list\n",
    "  r-packages.tsv   Full installed.packages() table\n",
    "  sessionInfo.txt  R session and platform details\n",
    "  libPaths.txt     Active R library paths\n\n",
    "Arguments:\n",
    "  OUTPUT_DIR       Backup directory. Defaults to r-env-backup.\n",
    sep = ""
  )
}

if (length(args) > 0 && args[[1]] %in% c("-h", "--help")) {
  show_help()
  quit(status = 0)
}

output_dir <- if (length(args) >= 1) args[[1]] else "r-env-backup"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

options(repos = c(CRAN = "https://cloud.r-project.org"))

install_if_missing <- function(package) {
  if (requireNamespace(package, quietly = TRUE)) {
    return(TRUE)
  }

  message("Installing missing package: ", package)
  tryCatch(
    {
      install.packages(package)
      requireNamespace(package, quietly = TRUE)
    },
    error = function(error) {
      warning("Unable to install ", package, ": ", conditionMessage(error))
      FALSE
    }
  )
}

extra_fields <- c(
  "Repository",
  "RemoteType",
  "RemoteHost",
  "RemoteRepo",
  "RemoteUsername",
  "RemoteRef",
  "RemoteSha"
)

packages <- as.data.frame(
  installed.packages(fields = extra_fields),
  stringsAsFactors = FALSE
)
packages <- packages[order(tolower(packages$Package)), , drop = FALSE]

write.table(
  packages,
  file = file.path(output_dir, "r-packages.tsv"),
  sep = "\t",
  quote = FALSE,
  row.names = FALSE
)

external <- is.na(packages$Priority) | !nzchar(packages$Priority)
requirements <- sprintf(
  "%s==%s",
  packages$Package[external],
  packages$Version[external]
)
writeLines(requirements, file.path(output_dir, "requirements.txt"))

writeLines(capture.output(sessionInfo()), file.path(output_dir, "sessionInfo.txt"))
writeLines(capture.output(.libPaths()), file.path(output_dir, "libPaths.txt"))
writeLines(capture.output(R.version), file.path(output_dir, "R.version.txt"))

if (requireNamespace("BiocManager", quietly = TRUE)) {
  writeLines(
    as.character(BiocManager::version()),
    file.path(output_dir, "bioconductor-version.txt")
  )
}

if (install_if_missing("renv")) {
  tryCatch(
    {
      renv::snapshot(
        lockfile = file.path(output_dir, "renv.lock"),
        type = "all",
        library = .libPaths(),
        prompt = FALSE,
        force = TRUE
      )
    },
    error = function(error) {
      warning("Unable to write renv.lock: ", conditionMessage(error))
    }
  )
} else {
  warning("renv is unavailable; restore will fall back to requirements.txt.")
}

message("R environment backup written to: ", normalizePath(output_dir))
