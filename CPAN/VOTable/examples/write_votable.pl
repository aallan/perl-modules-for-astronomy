#!/skyview/bin/perl -w

# write_votable.pl - Sample program illustrating the use of the
# VOTable modules to build and print a VOTABLE document.

# External modules
use VOTable::Document;

# FIELD element names, and cell data.
my(@field_names) = qw(ID RA DEC);
my(@rows) = (
	     ['A', '9.9', '8.8'],
	     ['B', '7.7', '6.6'],
	     ['C', '5.5', '4.4']
	     );

# Create the VOTABLE document.
my $doc = new VOTable::Document or die;

# Get the VOTABLE element.
my $votable = ($doc->get_VOTABLE)[0] or die;

# Create the RESOURCE element and add it to the VOTABLE.
my $resource = new VOTable::RESOURCE or die;
$votable->set_RESOURCE($resource);

# Create the DESCRIPTION element and its contents, and add it to the
# RESOURCE.
my $description = new VOTable::DESCRIPTION or die;
$description->set('This is another set of sample data in VOTABLE format.');

# Create the TABLE element and add it to the RESOURCE.
my $table = new VOTable::TABLE or die;
$resource->set_TABLE($table);

# Create and add the FIELD elements to the TABLE.
my($i);
my($field);
for ($i = 0; $i < @field_names; $i++) {
    $field = new VOTable::FIELD or die;
    $field->set_name($field_names[$i]);
    $table->append_FIELD($field);
}

# Create and append the DATA element.
my $data = new VOTable::DATA or die;
$table->set_DATA($data);

# Create and append the TABLEDATA element.
my $tabledata = new VOTable::TABLEDATA or die;
$data->set_TABLEDATA($tabledata);

# Create and append each TR element, and each TD element.
my($tr, $td);
my($j);
for ($i = 0; $i < @rows; $i++) {
    $tr = new VOTable::TR or die;
    for ($j = 0; $j < @field_names; $j++) {
	$td = new VOTable::TD or die;
	$td->set($rows[$i][$j]);
	$tr->append_TD($td);
    }
    $tabledata->append_TR($tr);
}

# Print the finished document.
print $doc->toString;

# Print it nicer!
print "\n";
print $doc->toString(1);

# Print it with way too much whitespace!
print "\n";
print $doc->toString(2);
