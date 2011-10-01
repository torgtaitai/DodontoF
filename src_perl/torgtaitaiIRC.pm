#--*-coding:utf-8-*--

package torgtaitaiIRC;

sub new{
    my $pkg = shift;
    my $args_org = shift;
    my $game_type = shift;
    
#    print("args_org : " . $args_org . "\n");
    
    my $hash= {
        args => $args_org,
        game_type => $game_type,
        isSecretMarkerPrinted => 0,
        isGameTypePrinted => 0
    };
    
    bless $hash,$pkg;
}

sub args {
    my $self = shift;
    return $self->{'args'};
}

sub to {
    return ('', '');
}

sub nick {
    return '';
}

sub privmsg {
    my $self = shift;
    my $to = shift;
    my $message = shift;
    
    #シークレットダイスの場合はここでマーカーを出力し、どどんとふにその旨を通達。
    #マーカーは1回だけ出力すれば十分なので2回目以降は抑止
    unless( $self->{'isSecretMarkerPrinted'} ) {
        print("##>isSecretDice<##");
        $self->{'isSecretMarkerPrinted'} = 1;
    }
    
    $self->notice($to, $message);
}

sub init {
    my $self = shift;
    $self->{'isGameTypePrinted'} = 0;
    $self->{'isSecretMarkerPrinted'} = 0;
}

sub notice {
    my $self = shift;
    my $to = shift;
    my $message = shift;
    
    print("\n");
    
    unless( $self->{'isGameTypePrinted'} ) {
        print( $self->{'game_type'} . " " );
        $self->{'isGameTypePrinted'} = 1;
    }
    
    print( $message );
}


sub newconn {
    my $self = shift;
    return $self;
}

sub add_handler() {
    my $self = shift;
    my $name = shift;
    my $function = shift;
    
    if( $name eq "public" ) {
        $self->$function( $self );
    }
}



sub add_global_handler {
}

sub start {
    my $self = shift;
}

1;
