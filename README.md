
<!-- README.md is generated from README.Rmd. Please edit that file -->

# musePHI

<!-- badges: start -->

[![R-CMD-check](https://github.com/overdodactyl/musePHI/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/overdodactyl/musePHI/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

`musePHI` is a package designed to assist in the de-identification of
MUSE ECG XML files. It enables users to replace sensitive patient
information within XML files with placeholders, maintaining the overall
structure of the files. This approach helps in ensuring patient privacy
while allowing the data to be used for research or analysis purposes.

## Disclaimer

It is the responsibility of the user to accurately identify and replace
values that need to be de-identified from the XML file. Furthermore,
users must validate the results to ensure no personal health information
(PHI) is inadvertently disclosed. The developers of `musePHI` assume no
liability for the misuse of this software or the inadvertent sharing of
PHI.

## Installation

You can install the development version of musePHI from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("overdodactyl/musePHI")
```

## Example

``` r
library(musePHI)
```

Define the elements you wish to replace in the MUSE XML file:

``` r
replace <- list(
  "PatientDemographics/PatientLastName" = "LastName",
  "PatientDemographics/PatientFirstName" = "FirstName",
  "PatientDemographics/PatientID" = "PatientID",
  "TestDemographics/AcquisitionDate" = "01-01-0001",
  "TestDemographics/AcquisitionTime" = "00:00:00"
)
```

For each element in the list, the name should be the path to an XML node
(relative to `RestingECG`). The value is what the node will be replaced
with.

Specify the path to your existing XML file and the path for the new
de-identified XML file. Then, call `muse_deidentify`:

``` r
file <- muse_example("muse/muse_ecg1.xml")
output_file <- tempfile(fileext = ".xml")
muse_deidentify(file, output_file, replace)
```

**NOTE:** It’s recommended to save the de-identified ECG data to a new
file to preserve the original data.

## Parallelization

For users working with a large number of XML files, parallelization can
significantly speed up the de-identification process. We recommend using
the [furrr](https://furrr.futureverse.org) package to efficiently
parallelize your workload.

To demonstrate this, we will process 10000 XML files sequentially and in
parallel using 10 CPUs.

First, create 10000 XML files in a temporary directory:

``` r

dir <- fs::path_temp("xmls")
fs::dir_create(dir)

for (i in 1:10000) {
  fs::file_copy(
    "inst/extdata/muse/muse_ecg1.xml",
    fs::file_temp(tmp_dir = dir, ext = ".xml")
  )
}
```

Next, create a list of XML files and create their new file paths:

``` r
xml_files <- fs::dir_ls(dir)
deidentified_dir <- fs::path_temp("deidentified_xmls")
fs::dir_create(deidentified_dir)
deidentified_xmls <- fs::path(deidentified_dir, fs::path_file(xml_files))
```

``` r
library(tictoc)
```

Run `muse_deidentify` sequentially:

``` r
tic()
for (i in seq_along(xml_files)) {
  muse_deidentify(xml_files[i], deidentified_xmls[i], replace)
}
toc()
#> 21.538 sec elapsed
```

Run in parallel:

``` r
library(furrr)
#> Loading required package: future
plan(multisession, workers = 10)
```

``` r
tic()
future_walk2(xml_files, deidentified_xmls, muse_deidentify, replace = replace)
toc()
#> 6.608 sec elapsed
```
