#!/usr/bin/env perl
use common::sense;
use utf8::all;
use Encode;
use Data::Dumper;

use Socket;
use Log::Log4perl qw(:easy);
use WWW::Mechanize::Chrome;

#sub d {
#    return decode( 'utf-8', $_[0] );
#}

sleep 10;

# Set priority of root logger to ERROR
Log::Log4perl->easy_init($ERROR);

warn "Using WWW::Mechanize::Chrome version " . $WWW::Mechanize::Chrome::VERSION . "\n";

my $chrome_ip;

eval {
    $chrome_ip = inet_ntoa(inet_aton("chrome"));
};

$chrome_ip ||= 'localhost';

my $mech;

eval {
    $mech = WWW::Mechanize::Chrome->new(
        host => $chrome_ip,
        port => 9222,
        reuse => 1,
        launch_arg => [
            '--window-size=1280x16960',
            '--disable-gpu',
            '--headless',
            '--no-sandbox',
            '--disable-dev-shm-usage',
        ],
        headless => 1,
    );
};

die "Can't run test - no Chrone connection!" unless $mech;

# TODO: take this from the environment
$mech->viewport_size({ width => 1388, height => 792 });

############################################ TESTS START HERE ##############################################
use Test::Simple "no_plan";

my $res = $mech->get('https://fantlab.ru');

my $status = $mech->status;

ok( $mech->status == 200, 'Site works');

die "Can't run - site not working!" unless $status == 200;

ok( $mech->content_encoding eq 'text/html;charset=UTF-8', 'Code page');
ok( $mech->base eq 'https://fantlab.ru/', 'Address');
ok( $mech->content_type eq 'text/html', 'Content type');
#ok( d($mech->title) eq 'Лаборатория Фантастики', 'Site title');
ok( $mech->title eq 'Лаборатория Фантастики', 'Site title');

my $user = $ENV{FL_USER};
my $pass = $ENV{PASSWORD};

ok( ref(($mech->selector('form.auth-form.bootstrap'))[0]) eq 'WWW::Mechanize::Chrome::Node', 'Login form');

# logging in
$res = $mech->submit_form(
    with_fields => {
        login    => $user,
        password => $pass,
    },
    strict_forms => 1
);

my @para_text = $mech->selector('div.left-block-body.clearfix > dl > dd b a');

ok( ref $para_text[0] eq 'WWW::Mechanize::Chrome::Node', 'User info panel exists');
ok(lc( $para_text[0]->get_attribute('innerText') ) eq lc($user), 'Found proper user login');
