package Dashboard::Tab::AndroidClient;

use base qw(Dashboard::Tab);

use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / MyFrame /

  ];

sub init {
  my ($self,%args) = @_;
  $self->MyFrame($args{Frame});
}

1;
