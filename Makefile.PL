use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Class::DBI::FromSledge',
    'VERSION_FROM' => 'lib/Class/DBI/FromSledge.pm', # finds $VERSION
    'PREREQ_PM'    => {
        Test::More         => 0.32,
        Test::Exception    => 0.21,
        Class::DBI::Plugin => 0.03,
    },
);
