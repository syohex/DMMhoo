use strict;
use warnings;
use utf8;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname(__FILE__), 'extlib', 'lib', 'perl5');
use lib File::Spec->catdir(dirname(__FILE__), 'lib');
use Amon2::Lite;
use Config::Pit;
use WebService::DMM;
use Encode;

our $VERSION = '0.01';

my $config = pit_get('dmm.co.jp', require => {
    affiliate_id => 'DMM Affiliate ID',
    api_id       => 'DMM API ID',
});

my $dmm = WebService::DMM->new(
    affiliate_id => $config->{affiliate_id},
    api_id       => $config->{api_id},
);

# put your configuration here
sub load_config {
    +{}
}

get '/' => sub {
    my $c = shift;
    return $c->render('index.tt');
};

any '/search' => sub {
    my $c = shift;

    my $query = $c->req->param('query');
    my $page = $c->req->param('page') || 1;

    if ($query) {
        $c->session->set(query => $query);
    } else {
        $query = $c->session->get('query');
    }

    my $res = $dmm->search(
        site    => 'DMM.co.jp',
        service => 'digital',
        floor   => 'videoa',
        hits    => 100,
        keyword => Encode::decode_utf8($query),
        offset  => (($page - 1) * 100) + 1,
    );

    my @results;
    for my $item (@{$res->items}) {
        push @results, {
            title => $item->title,
            image => $item->image('small'),
            url   => $item->affiliate_url,
        };
    }

    my $total_count = int($res->total_count / 100) + 1;
    return $c->render('search.tt' => {
        query   => $query,
        results => \@results,
        pages   => $total_count,
    });
};

# load plugins
__PACKAGE__->load_plugin('Web::CSRFDefender');
__PACKAGE__->enable_session();
__PACKAGE__->to_app(handle_static => 1);

__DATA__

@@ index.tt
<!doctype html>
<html>
<head>
    <meta charset="utf-8">
    <title>DMMhoo</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.8.0/jquery.min.js"></script>
    <script type="text/javascript" src="[% uri_for('/static/js/main.js') %]"></script>
    <link rel="stylesheet" href="http://twitter.github.com/bootstrap/1.4.0/bootstrap.min.css">
    <link rel="stylesheet" href="[% uri_for('/static/css/main.css') %]">
</head>
<body>
    <div class="container">
        <header><h1>DMMhoo</h1></header>
        <form method="post" action="[% uri_for('/search') %]">
            <input type="text" name="query" />
            <input type="submit" value="Send" />
        </form>
        <footer>Powered by <a href="http://amon.64p.org/">Amon2::Lite</a></footer>
    </div>
</body>
</html>

@@ search.tt

<!doctype html>
<html>
<head>
    <meta charset="utf-8">
    <title>DMMhoo</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.8.0/jquery.min.js"></script>
    <link rel="stylesheet" href="http://twitter.github.com/bootstrap/1.4.0/bootstrap.min.css">
    <link rel="stylesheet" href="[% uri_for('/static/css/main.css') %]">
</head>
<body>
    <div class="container">
    <header><h1>Result [% query %]<a href="/">(戻る)</a></h1></header>
    <table>
        [% FOR result IN results %]
           [% IF loop.index % 5 == 0 %] <tr> [% END %]
           <td>
           [% result.title %] <br />
           <a href="[% result.url %]"><img src="[% result.image %]" /></a>
           </td>
           [% IF loop.index % 5 == 4 || loop.is_last %] </tr> [% END %]
        [% END %]
        </table>
        <p>
        [% FOR page IN [1..$pages] %]
           <a href="/search?page=[% page %]">[% page %]</a>&nbsp;
        [% END %]
        </p>
        <footer>Powered by <a href="http://amon.64p.org/">Amon2::Lite</a></footer>
    </div>
</body>
</html>

@@ /static/css/main.css
footer {
    text-align: right;
}
