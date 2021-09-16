#' Remove patient names from a MUSE XML
#'
#' Reads an XML file, removes patient first and last name, and writes out a new XML
#'
#' @param file Input file name
#' @param output_file Output file name
#'
#' @return Silently returns `output_file`
#' @export
#'
muse_strip_names <- function(file, output_file) {
  doc <- xml2::read_xml(file)

  xml2::xml_remove( xml2::xml_find_all(doc, ".//PatientLastName"))
  xml2::xml_remove(xml2::xml_find_all(doc, ".//PatientFirstName"))

  xml2::write_xml(doc, output_file)

  invisible(output_file)

}
