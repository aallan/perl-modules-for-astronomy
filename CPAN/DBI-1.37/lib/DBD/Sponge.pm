{
    package DBD::Sponge;

    require DBI;
    require Carp;

    @EXPORT = qw(); # Do NOT @EXPORT anything.
    $VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/o);

#   $Id: Sponge.pm,v 1.1 2003/07/18 00:20:55 aa Exp $
#
#   Copyright (c) 1994-2003 Tim Bunce Ireland
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.

    $drh = undef;	# holds driver handle once initialised
    $err = 0;		# The $DBI::err value

    sub driver{
	return $drh if $drh;

	DBD::Sponge::db->install_method("sponge_test_installed_method");

	my($class, $attr) = @_;
	$class .= "::dr";
	($drh) = DBI::_new_drh($class, {
	    'Name' => 'Sponge',
	    'Version' => $VERSION,
	    'Attribution' => "DBD::Sponge $VERSION (fake cursor driver) by Tim Bunce",
	    });
	$drh;
    }

    sub default_user {
        return ('','');
    }
}


{   package DBD::Sponge::dr; # ====== DRIVER ======
    $imp_data_size = 0;
    # we use default (dummy) connect method
}


{   package DBD::Sponge::db; # ====== DATABASE ======
    $imp_data_size = 0;
    use strict;

    sub prepare {
	my($dbh, $statement, $attribs) = @_;
	my $rows = delete $attribs->{'rows'}
	    or return $dbh->set_err(1,"No rows attribute supplied to prepare");
	my ($outer, $sth) = DBI::_new_sth($dbh, {
	    'Statement'   => $statement,
	    'rows'        => $rows,
	    (map { exists $attribs->{$_} ? ($_=>$attribs->{$_}) : () }
		qw(execute_hook)
	    ),
	});
	if (my $behave_like = $attribs->{behave_like}) {
	    $outer->{$_} = $behave_like->{$_}
		foreach (qw(RaiseError PrintError HandleError ShowErrorStatement));
	}

	if ($statement =~ /^\s*insert\b/) {	# very basic, just for testing execute_array()
	    $sth->{is_insert} = 1;
	    my $NUM_OF_PARAMS = $attribs->{NUM_OF_PARAMS}
		or return $dbh->set_err(1,"NUM_OF_PARAMS not specified for INSERT statement");
	    $sth->STORE('NUM_OF_PARAMS' => $attribs->{NUM_OF_PARAMS} );
	}
	else {	#assume select

	    # we need to set NUM_OF_FIELDS
	    my $numFields;
	    if ($attribs->{'NUM_OF_FIELDS'}) {
		$numFields = $attribs->{'NUM_OF_FIELDS'};
	    } elsif ($attribs->{'NAME'}) {
		$numFields = @{$attribs->{NAME}};
	    } elsif ($attribs->{'TYPE'}) {
		$numFields = @{$attribs->{TYPE}};
	    } elsif (my $firstrow = $rows->[0]) {
		$numFields = scalar @$firstrow;
	    } else {
		DBI::set_err($dbh, 1, 'Cannot determine NUM_OF_FIELDS');
		return undef;
	    }
	    $sth->STORE('NUM_OF_FIELDS' => $numFields);
	    $sth->{NAME} = $attribs->{NAME}
		    || [ map { "col$_" } 1..$numFields ];
	    $sth->{TYPE} = $attribs->{TYPE}
		    || [ (DBI::SQL_VARCHAR()) x $numFields ];
	    $sth->{PRECISION} = $attribs->{PRECISION}
		    || [ map { length($sth->{NAME}->[$_]) } 0..$numFields -1 ];
	}

	$outer;
    }

    sub type_info_all {
	my ($dbh) = @_;
	my $ti = [
	    {	TYPE_NAME	=> 0,
		DATA_TYPE	=> 1,
		PRECISION	=> 2,
		LITERAL_PREFIX	=> 3,
		LITERAL_SUFFIX	=> 4,
		CREATE_PARAMS	=> 5,
		NULLABLE	=> 6,
		CASE_SENSITIVE	=> 7,
		SEARCHABLE	=> 8,
		UNSIGNED_ATTRIBUTE=> 9,
		MONEY		=> 10,
		AUTO_INCREMENT	=> 11,
		LOCAL_TYPE_NAME	=> 12,
		MINIMUM_SCALE	=> 13,
		MAXIMUM_SCALE	=> 14,
	    },
	    [ 'VARCHAR', DBI::SQL_VARCHAR(), undef, "'","'", undef, 0, 1, 1, 0, 0,0,undef,0,0 ],
	];
	return $ti;
    }

    sub FETCH {
        my ($dbh, $attrib) = @_;
        # In reality this would interrogate the database engine to
        # either return dynamic values that cannot be precomputed
        # or fetch and cache attribute values too expensive to prefetch.
        return 1 if $attrib eq 'AutoCommit';
        # else pass up to DBI to handle
        return $dbh->SUPER::FETCH($attrib);
    }

    sub STORE {
        my ($dbh, $attrib, $value) = @_;
        # would normally validate and only store known attributes
        # else pass up to DBI to handle
        if ($attrib eq 'AutoCommit') {
            return 1 if $value; # is already set
            Carp::croak("Can't disable AutoCommit");
        }
        return $dbh->SUPER::STORE($attrib, $value);
    }

    sub sponge_test_installed_method {
	my ($dbh, @args) = @_;
	return $dbh->set_err(42, "not enough parameters") unless @args >= 2;
	return \@args;
    }
}


{   package DBD::Sponge::st; # ====== STATEMENT ======
    $imp_data_size = 0;
    use strict;

    sub execute {
	my $sth = shift;
	if (my $hook = $sth->{execute_hook}) {
	    &$hook($sth, @_) or return;
	}

	if ($sth->{is_insert}) {
	    my $row;
	    $row = (@_) ? [ @_ ] : die "bind_param not supported yet" ;
	    my $NUM_OF_PARAMS = $sth->{NUM_OF_PARAMS};
	    return $sth->set_err(1, @$row." values bound (@$row) but $NUM_OF_PARAMS expected")
		if @$row != $NUM_OF_PARAMS;
	    { local $^W; $sth->trace_msg("inserting (@$row)\n"); }
	    push @{ $sth->{rows} }, $row;
	}
	else {	# mark select sth as Active
	    $sth->STORE(Active => 1);
	}
	# else do nothing for select as data is already in $sth->{rows}
	return 1;
    }

    sub fetch {
	my ($sth) = @_;
	my $row = shift @{$sth->{'rows'}};
	unless ($row) {
	    $sth->STORE(Active => 0);
	    return undef;
	}
	return $sth->_set_fbav($row);
    }
    *fetchrow_arrayref = \&fetch;

    sub FETCH {
	my ($sth, $attrib) = @_;
	# would normally validate and only fetch known attributes
	# else pass up to DBI to handle
	return $sth->SUPER::FETCH($attrib);
    }

    sub STORE {
	my ($sth, $attrib, $value) = @_;
	# would normally validate and only store known attributes
	# else pass up to DBI to handle
	return $sth->SUPER::STORE($attrib, $value);
    }
}

1;
