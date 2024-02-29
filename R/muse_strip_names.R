#' De-identify Muse XML Files
#'
#' This function de-identifies XML files containing patient data from Muse ECG systems by replacing specified elements with anonymized values.
#' The function targets specific nodes within the `RestingECG` element of the XML document based on a provided list of elements to be replaced.
#'
#' @param file A string specifying the path to the input XML file to be de-identified.
#' @param output_file A string specifying the path where the de-identified XML file will be saved.
#' @param replace A named list where each name is a path to an XML node (relative to the `RestingECG` root) and its value is the replacement text.
#' For example, `list("PatientDemographics/PatientLastName" = "LastName")` would replace the text of the `PatientLastName` element within `PatientDemographics`.
#'
#' @return Invisibly returns the path to the output file containing the de-identified XML document. The function primarily operates through side effects (reading an input file, modifying its content, and writing the result to a new file).
#' @export
#' @examples
#' # De-identify a sample Muse ECG XML file
#' replace <- list(
#'   "PatientDemographics/PatientLastName" = "LastName",
#'   "PatientDemographics/PatientFirstName" = "FirstName",
#'   "PatientDemographics/PatientID" = "AnonymousID",
#'   "TestDemographics/AcquisitionDate" = "01-01-0001",
#'   "TestDemographics/AcquisitionTime" = "00:00:00"
#' )
#' file <- muse_example("muse/muse_ecg1.xml")
#' output_file <- tempfile(fileext = ".xml")
#' muse_deidentify(file, output_file, replace)
#'
#' @import xml2
#' @note Make sure the paths provided in `replace` accurately reflect the structure of your XML documents.
#' @seealso \code{\link[xml2]{read_xml}}, \code{\link[xml2]{write_xml}} for the underlying XML manipulation functions used.
muse_deidentify <- function(file, output_file, replace) {
  # Read the XML file
  doc <- xml2::read_xml(file)

  # Iterate over the replace list and replace text
  for (path_suffix in names(replace)) {
    full_xpath <- paste0("//RestingECG/", path_suffix)
    replacement_text <- replace[[path_suffix]]
    nodes <- xml2::xml_find_all(doc, full_xpath)
    if(length(nodes) > 0) {
      xml2::xml_text(nodes) <- replacement_text
    }
  }

  # Write the modified XML to the specified output file
  xml2::write_xml(doc, output_file)

  # Return the path to the modified file invisibly
  invisible(output_file)
}

#' Get path to sample XML file
#'
#' musePHI comes with a few sample files in the inst/extdata directory.
#'     This is a convenience function to access them
#'
#' @param path Name of file. If NULL, the example files will be listed.
#'
#' @export
#'
#' @examples
#' muse_example(path = NULL)
#' muse_example(path = "muse/muse_ecg1.xml")
muse_example <- function(path = NULL) {
  if (is.null(path)) {
    dir(system.file("extdata", package = "musePHI"))
  }
  else {
    system.file("extdata", path, package = "musePHI", mustWork = TRUE)
  }
}






