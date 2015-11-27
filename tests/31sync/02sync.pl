push our @EXPORT, qw( matrix_sync );

=head2 matrix_sync

   my ( $sync_body ) = matrix_sync( $user, %query_params )->get;

Make a v2_alpha/sync request for the user. Returns the response body as a
reference to a hash.

=cut

sub matrix_sync
{
   my ( $user, %params ) = @_;

   do_request_json_for( $user,
      method  => "GET",
      uri     => "/v2_alpha/sync",
      params  => \%params,
   )->on_done( sub {
      my ( $body ) = @_;

      assert_json_keys( $body, qw( rooms presence next_batch ) );
      assert_json_keys( $body->{presence}, qw( events ));
      assert_json_keys( my $rooms = $body->{rooms}, qw( join invite leave ) );
   });
}


test "Can sync",
    requires => [ local_user_fixture( with_events => 0 ),
                  qw( can_create_filter )],

    provides => [qw( can_sync )],

    do => sub {
       my ( $user ) = @_;

       my $filter_id;

       matrix_create_filter( $user, {} )->then( sub {
          ( $filter_id ) = @_;

          matrix_sync( $user, filter => $filter_id )
       })->then( sub {
          my ( $body ) = @_;

          matrix_sync( $user,
             filter => $filter_id,
             since => $body->{next_batch},
          )
       })->then( sub {
          provide can_sync => 1;

          Future->done(1);
       })
    };
