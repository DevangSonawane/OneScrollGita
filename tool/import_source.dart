// Importer for the authorised source files.
//
// BLOCKED: the format of the authorised source is not known yet (PRD open
// question 1). Once the files are in source/, map their fields to the JSON
// schema in PRD section 3 and implement the conversion here. This script and
// tool/generate_placeholder.dart are the only things allowed to write into
// assets/scripture/. Never hand-edit, correct or generate scripture text.
import 'dart:io';

void main() {
  stderr.writeln(
    'The real importer is not implemented yet: supply the authorised source '
    'files in source/ and describe their format first.',
  );
  exit(2);
}
