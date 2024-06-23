#' De-identify Muse XML Files
#'
#' This function de-identifies Muse ECG XML files by replacing specified
#' elements with anonymized values using regex patterns.
#'
#' @param file Path to the input XML file to be de-identified.
#' @param output_file Path where the de-identified XML file will be saved.
#' @param replace A named list where each name is an XPath to an XML node and
#' its value is a list of regex patterns and replacements. For example,
#' `list("//PatientDemographics/PatientLastName" = list(".*" = "LastName"))`
#' replaces the text of the `PatientLastName` element within `PatientDemographics`.#'
#'
#' @return Invisibly returns the path to the output file containing the
#' de-identified XML document. The function primarily operates through side
#' effects (reading an input file, modifying its content, and writing the
#' result to a new file).
#' @export
#' @examples
#' # De-identify a sample Muse ECG XML file
#'
#'
#' # For diagnosis statements, we will remove only specific text (like dates)
#' # rather than the full nodes
#'
#' # Create a string of valid month abbreviations
#' months <- paste(toupper(month.abb), collapse = "|")
#'
#' dx_replace <- setNames(
#'   list(
#'     "XX-XXX-XXXX XX:XX",  # Replacement for date-time format
#'     "XX-XXX-XXXX",        # Replacement for date format
#'     "Confirmed by XXX (XX) on XX/XX/XXXX XX:XX:XX XM" # Replacement for confirmation format
#'   ),
#'   c(
#'     paste0("\\d{2}-(", months, ")-\\d{4} \\d{2}:\\d{2}"),
#'     paste0("\\d{2}-(", months, ")-\\d{4}"),
#'     "Confirmed by [A-Za-z]+, [A-Za-z]+ \\(\\d+\\) on \\d{1,2}/\\d{1,2}/\\d{4} \\d{1,2}:\\d{2}:\\d{2} [APM]+"
#'   )
#' )
#'
#' replace <- list(
#'   "/RestingECG/PatientDemographics/PatientLastName" = list(".*" = "LastName"),
#'   "/RestingECG/PatientDemographics/PatientFirstName" = list(".*" = "FirstName"),
#'   "/RestingECG/PatientDemographics/PatientID" = list(".*" = "PatientID"),
#'   "/RestingECG/PatientDemographics/DateofBirth" = list(".*" = "XXXX"),
#'   "/RestingECG/Diagnosis/DiagnosisStatement/StmtText" = dx_replace,
#'   "/RestingECG/OriginalDiagnosis/DiagnosisStatement/StmtText" = dx_replace
#'  )
#' file <- muse_example("muse/muse_ecg1.xml")
#' output_file <- tempfile(fileext = ".xml")
#' muse_deidentify(file, output_file, replace)
#'
#' @import xml2
#' @note Ensure the paths in `replace` accurately reflect your XML structure.
#' @seealso \code{\link[xml2]{read_xml}}, \code{\link[xml2]{write_xml}} for the
#' underlying XML manipulation functions used.
muse_deidentify <- function(file, output_file, replace = list()) {
  # Read the XML file and extract the encoding from the XML declaration
  xml_content <- readLines(file, warn = FALSE)
  xml_declaration <- xml_content[1]
  original_encoding <- sub('.*encoding="([^"]+)".*', '\\1', xml_declaration)

  # Create an XML document from the text
  doc <- xml2::read_xml(paste(xml_content, collapse = "\n"), options = "NOENT")

  # Iterate through the replacements list and apply the replacements
  for (node in names(replace)) {
    node_replacements <- replace[[node]]

    # Find all specified nodes
    target_nodes <- xml2::xml_find_all(doc, node)

    # Iterate over all target nodes
    for (target_node in target_nodes) {
      text <- xml2::xml_text(target_node)

      # Apply each pattern replacement to the text content
      for (pattern in names(node_replacements)) {
        replacement_value <- node_replacements[[pattern]]
        text <- gsub(pattern, replacement_value, text, perl = TRUE)
      }

      # Set the modified text back to the node
      xml2::xml_text(target_node) <- text
    }
  }

  # Write the modified XML content to the specified output file with the original encoding
  xml2::write_xml(doc, output_file, encoding = original_encoding)

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


#' Read all diagnoses in an XML file
#'
#' Generate a data frame of all values from `StmtFlag` and `StmtText` nodes
#'     within the `OriginalDiagnosis` and `Diagnosis` sections of an XML file.
#' @param file Path to the input XML file
#'
#' @export
#' @examples
#' file <- muse_example("muse/muse_ecg1.xml")
#' diagnoses <- muse_diagnoses(file)
#' dplyr::count(diagnoses, value, sort = TRUE)
muse_diagnoses <- function(file) {
  # Read the XML file
  doc <- xml2::read_xml(file)

  # Function to extract Diagnosis Statements
  extract_statements <- function(diagnosis_section, diagnosis_type) {
    modality <- xml2::xml_text(xml2::xml_find_first(diagnosis_section, "Modality"))
    statements <- xml2::xml_find_all(diagnosis_section, "DiagnosisStatement")

    purrr::map_dfr(seq_along(statements), function(i) {
      statement <- statements[i]
      stmt_flags <- xml2::xml_find_all(statement, "StmtFlag")
      stmt_texts <- xml2::xml_find_all(statement, "StmtText")

      flag_tibble <- dplyr::tibble(
        file = file,
        diagnosis_id = i,
        diagnosis_type = diagnosis_type,
        modality = modality,
        tag = "StmtFlag",
        value = xml2::xml_text(stmt_flags)
      )

      text_tibble <- dplyr::tibble(
        file = file,
        diagnosis_id = i,
        diagnosis_type = diagnosis_type,
        modality = modality,
        tag = "StmtText",
        value = xml2::xml_text(stmt_texts)
      )

      dplyr::bind_rows(flag_tibble, text_tibble)
    })
  }

  # Extract data for both Diagnosis and OriginalDiagnosis
  diagnosis_section <- xml2::xml_find_first(doc, "//Diagnosis")
  original_diagnosis_section <- xml2::xml_find_first(doc, "//OriginalDiagnosis")

  diagnosis_data <- dplyr::bind_rows(
    extract_statements(diagnosis_section, "Diagnosis"),
    extract_statements(original_diagnosis_section, "OriginalDiagnosis")
  )

  diagnosis_data
}






