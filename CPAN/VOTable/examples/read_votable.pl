#!/skyview/bin/perl -w

# read_votable.pl - Sample program illustrating the use of the VOTable
# modules to read a VOTABLE document and access its parts.

# External modules
use VOTable::Document;

# Read the VOTABLE document.
my $doc = new_from_file VOTable::Document 'votable.xml' or die;

# Get the VOTABLE element.
my $votable = ($doc->get_VOTABLE)[0] or die;

# Get the RESOURCE element.
my $resource = ($votable->get_RESOURCE)[0] or die;

# Get the DESCRIPTION element and its contents.
my $description = ($resource->get_DESCRIPTION)[0] or die;
print $description->get, "\n";

# Get the TABLE element.
my $table = ($resource->get_TABLE)[0] or die;

# Get the FIELD elements.
my(@field_names) = ();
my($field);
foreach $field ($table->get_FIELD) {
    push(@field_names, $field->get_name);
}

# Get the DATA element.
my $data = ($table->get_DATA)[0] or die;

# Get the TABLEDATA element.
my $tabledata = ($data->get_TABLEDATA)[0] or die;

# Get each TR element, then each TD element, and print its contents.
my($tr, $td);
my($i, $j);
$i = 0;
foreach $tr ($tabledata->get_TR) {
    print "Data for target $i:\n";
    $j = 0;
    foreach $td ($tr->get_TD) {
	print "$field_names[$j] = ", $td->get, "\n";
	$j++;
    }
    $i++;
}

# Now go back and do it a little easier.

# Get the number of table rows.
my $num_rows = $table->get_num_rows or die;
print "num_rows = $num_rows\n";

# Print a table.

# Create the table header.
print join("\t", ('i', @field_names)), "\n";
for ($i = 0; $i < $num_rows; $i++) {
    print join("\t", ($i, $table->get_row($i))), "\n";
}

# Now go back and get the entire data table in one fell swoop.
my $cells = $table->get_array or die;
for ($i = 0; $i < @{$cells}; $i++) {
    for ($j = 0; $j < @{$cells->[$i]}; $j++) {
	print "i = $i, j = $j, cell = ", $cells->[$i][$j], "\n";
    }
}

# Now go back and get the contents one cell at a time.
print "\n";
for ($i = 0; $i < @{$cells}; $i++) {
    for ($j = 0; $j < @{$cells->[$i]}; $j++) {
	print "i = $i, j = $j, cell = ", $table->get_cell($i, $j), "\n";
    }
}

use Data::Dumper;
my(@kids) = $table->getElementsByTagName('FRED');
print "kids = >", Dumper(@kids), "<\n";
print scalar(@kids);

print $table->nodeName;
