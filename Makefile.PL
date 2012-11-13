use inc::Module::Install;
use Module::Install::ReadmePodFromPod;
name 'GarbageDay';
all_from 'lib/GarbageDay.pm';
readme_pod_from 'lib/GarbageDay.pm';

requires 'Any::Moose';
requires 'Mouse';
requires 'YAML';
requires 'Email::Send';
requires 'Email::MIME';
requires 'Digest::SHA1';
requires 'LWP::UserAgent';

install_script 'bin/garbageday';

tests 't/*.t';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
