
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

The function takes an input XML file, an output file path, and a list of
replacement patterns. Each replacement pattern is applied to the text
content of specified XML nodes.

The example below shows how regular expressions can be used to replace
entire nodes are patterns within nodes.

In order to capture dates and date times within the diagnoses sections,
we will construct some regular expressions:

``` r
# Create a string of valid month abbreviations
months <- paste(toupper(month.abb), collapse = "|")

# Define regex replacements with specific month abbreviations
dx_replace <- setNames(
  list(
    # Replacement for date-time format
    "XX-XXX-XXXX XX:XX",  
    # Replacement for date format
    "XX-XXX-XXXX",     
    # Replacement for confirmation format
    "Confirmed by XXX (XX) on XX/XX/XXXX XX:XX:XX XM" 
  ),
  c(
    paste0("\\d{2}-(", months, ")-\\d{4} \\d{2}:\\d{2}"),
    paste0("\\d{2}-(", months, ")-\\d{4}"),
    "Confirmed by [A-Za-z]+, [A-Za-z]+ \\(\\d+\\) on \\d{1,2}/\\d{1,2}/\\d{4} \\d{1,2}:\\d{2}:\\d{2} [APM]+"
  )
)
```

Below, we construct a full list of replacements. `".*"` is used to
replace an entire node.

``` r
replace <- list(
  "/RestingECG/PatientDemographics/PatientLastName" = list(".*" = "LastName"),
  "/RestingECG/PatientDemographics/PatientFirstName" = list(".*" = "FirstName"),
  "/RestingECG/PatientDemographics/PatientID" = list(".*" = "PatientID"),
  "/RestingECG/PatientDemographics/DateofBirth" = list(".*" = "XXXX"),
  "/RestingECG/TestDemographics/AcquisitionTime" = list(".*" = "XXXX"),
  "/RestingECG/TestDemographics/AcquisitionDate" = list(".*" = "XXXX"),
  "/RestingECG/Diagnosis/DiagnosisStatement/StmtText" = dx_replace,
  "/RestingECG/OriginalDiagnosis/DiagnosisStatement/StmtText" = dx_replace
)
```

Specify the path to your existing XML file and the path for the new
de-identified XML file. Then, call `muse_deidentify`:

``` r
file <- muse_example("muse/muse_ecg1.xml")
output_file <- tempfile(fileext = ".xml")
muse_deidentify(file, output_file, replace)
```

We recommend use a file diff viewer to visually inspect some
replacements to make sure only the intended changes are being made.

This could be done with the `diffviewer` R package:

``` r
diffviewer::visual_diff(file, output_file)
```

<img src="man/figures/diffviewer.png" width="100%" />

It could also be done via the `diff` linux tool:

``` r
cmd <- paste("diff -u", file, output_file)
res <- system(cmd, intern = TRUE)
#> Warning in system(cmd, intern = TRUE): running command 'diff -u
#> /apps/scratch/RtmpPXPjzJ/temp_libpath2a85bc7140f2a3/musePHI/extdata/muse/muse_ecg1.xml
#> /apps/scratch/Rtmpqkc0f0/file2a954842343b58.xml' had status 1
cat(res, sep = "\n")
#> --- /apps/scratch/RtmpPXPjzJ/temp_libpath2a85bc7140f2a3/musePHI/extdata/muse/muse_ecg1.xml   2024-06-23 17:09:21.546756534 -0500
#> +++ /apps/scratch/Rtmpqkc0f0/file2a954842343b58.xml  2024-06-23 17:09:29.090755967 -0500
#> @@ -5,11 +5,11 @@
#>        <MuseVersion>9.0.9.18167</MuseVersion>
#>     </MuseInfo>
#>     <PatientDemographics>
#> -      <PatientID>JAX01234</PatientID>
#> +      <PatientID>PatientID</PatientID>
#>        <PatientAge>60</PatientAge>
#>        <AgeUnits>YEARS</AgeUnits>
#>        <Gender>MALE</Gender>
#> -      <PatientLastName>TEST 05</PatientLastName>
#> +      <PatientLastName>LastName</PatientLastName>
#>     </PatientDemographics>
#>     <TestDemographics>
#>        <DataType>RESTING</DataType>
#> @@ -21,8 +21,8 @@
#>        <Priority>NORMAL</Priority>
#>        <Location>7</Location>
#>        <LocationName>FL Research Location</LocationName>
#> -      <AcquisitionTime>13:15:18</AcquisitionTime>
#> -      <AcquisitionDate>05-10-2021</AcquisitionDate>
#> +      <AcquisitionTime>XXXX</AcquisitionTime>
#> +      <AcquisitionDate>XXXX</AcquisitionDate>
#>        <CartNumber>56</CartNumber>
#>        <AcquisitionSoftwareVersion>010B</AcquisitionSoftwareVersion>
#>        <AnalysisSoftwareVersion>241</AnalysisSoftwareVersion>
#> @@ -88,7 +88,7 @@
#>        </DiagnosisStatement>
#>        <DiagnosisStatement>
#>           <StmtFlag>ENDSLINE</StmtFlag>
#> -         <StmtText>10-MAY-2021 14:14,</StmtText>
#> +         <StmtText>XX-XXX-XXXX XX:XX,</StmtText>
#>        </DiagnosisStatement>
#>        <DiagnosisStatement>
#>           <StmtFlag>ENDSLINE</StmtFlag>
#> @@ -97,7 +97,7 @@
#>        </DiagnosisStatement>
#>        <DiagnosisStatement>
#>           <StmtFlag>ENDSLINE</StmtFlag>
#> -         <StmtText>Confirmed by Doe, John (123456) on 05/10/2021 1:15:09 PM</StmtText>
#> +         <StmtText>Confirmed by XXX (XX) on XX/XX/XXXX XX:XX:XX XM</StmtText>
#>        </DiagnosisStatement>
#>     </Diagnosis>
#>     <OriginalDiagnosis>
#> @@ -130,7 +130,7 @@
#>        </DiagnosisStatement>
#>        <DiagnosisStatement>
#>           <StmtFlag>ENDSLINE</StmtFlag>
#> -         <StmtText>10-MAY-2021 18:34,</StmtText>
#> +         <StmtText>XX-XXX-XXXX XX:XX,</StmtText>
#>        </DiagnosisStatement>
#>        <DiagnosisStatement>
#>           <StmtFlag>ENDSLINE</StmtFlag>
```

**NOTE:** It is recommended to save the de-identified ECG data to a new
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

for (i in 1:100) {
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
#> 0.464 sec elapsed
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
#> 3.32 sec elapsed
```

# Summarizing Diagnosis Data

``` r
diagnoses <- future_map_dfr(deidentified_xmls, muse_diagnoses)

diagnoses |> 
  dplyr::count(value, sort = TRUE)
#> # A tibble: 14 × 2
#>    value                                                  n
#>    <chr>                                              <int>
#>  1 ENDSLINE                                            1100
#>  2 USERINSERT                                           200
#>  3 When compared with ECG of                            200
#>  4 XX-XXX-XXXX XX:XX,                                   200
#>  5 , age undetermined                                   100
#>  6 Abnormal ECG                                         100
#>  7 Confirmed by XXX (XX) on XX/XX/XXXX XX:XX:XX XM      100
#>  8 Lateral infarct                                      100
#>  9 Left axis deviation                                  100
#> 10 No significant change.                               100
#> 11 Non-specific intra-ventricular conduction block      100
#> 12 Previous ECG has undetermined rhythm, needs review   100
#> 13 Ventricular-paced rhythm                             100
#> 14 Wide QRS rhythm                                      100
```
