# A utilizar únicamente en Windows.

use 5.022_002;
use strict;
use warnings;
use utf8;
use Carp;
use English qw(-no_match_vars);

use Win32::Daemon;
use Cwd 'abs_path';
use File::Basename;

my $NOMBRE      = 'experimento';
my $NOMBRE_REAL = 'no-correr-directamente.pl';

my ( $log, $PAUSA, $daemon, $no_me_canso );

################################################################################
############################### SUBRUTINAS #####################################
################################################################################

sub preparar_servicio {
    my $argumentos = shift;

    $log         = $argumentos->{log};
    $PAUSA       = $argumentos->{pausa};
    $daemon      = $argumentos->{daemon};
    $no_me_canso = $argumentos->{no_me_canso};

    # No queremos pausar ni continuar.
    #my $accepted_controls = Win32::Daemon::AcceptedControls();
    #$accepted_controls &= ~SERVICE_ACCEPT_PAUSE_CONTINUE;
    #Win32::Daemon::AcceptedControls($accepted_controls);

    # Registramos los callbacks.
    Win32::Daemon::RegisterCallbacks(
        {   start   => \&Callback_Start,
            running => \&Callback_Running,
            stop    => \&Callback_Stop,
			pause => \&Callback_Pause,
			continue => \&Callback_Continue,
        }
    );

    my %Context = (
        last_state => SERVICE_STOPPED,
        start_time => time(),
    );

    # Arrancamos el servicio refrescando cada $PAUSA segundos.
    Win32::Daemon::StartService( \%Context, ( $PAUSA * 1000 ) );

    return;
}

sub comprobar_corriendo {
    if ( SERVICE_RUNNING == Win32::Daemon::State() ) {
        return 1;
    }
    return 0;
}

sub Callback_Running {
    my ( $Event, $Context ) = @_;

    # Mientras el estado sea running, no paramos.
    if ( SERVICE_RUNNING == Win32::Daemon::State() ) {
        $daemon->();

# En Windows 7 hay que forzar a que siga el running, o se cree que el servicio ha parado.
        $Context->{last_state} = SERVICE_RUNNING;
        Win32::Daemon::State(SERVICE_RUNNING);
    }
    return;
}

sub Callback_Start {
    my ( $Event, $Context ) = @_;

    $log->info('Arrancando servicio');

    return (SERVICE_RUNNING);
}

sub Callback_Stop {
    my ( $Event, $Context ) = @_;

    $log->info('Parando...');
    ${$no_me_canso} = 0;

    # Le notificamos que nos paramos.
    Win32::Daemon::StopService();
    return SERVICE_STOPPED;
}

sub Callback_Pause {
    my ( $Event, $Context ) = @_;

    $log->info('Pausando...');

    # Le notificamos que nos pausamos.
    return SERVICE_PAUSED;
}

sub Callback_Continue {
    my ( $Event, $Context ) = @_;

    $log->info('Continuando...');

    # Le notificamos que continuamos.
    return SERVICE_RUNNING;
}

sub instalar {

    # Para configurar el servicio necesitamos la ruta absoluta.
    my ( $nombre, $ruta ) = fileparse( abs_path($PROGRAM_NAME) );

    my $service_info = {
        machine     => q{},
        name        => $NOMBRE,
        display     => $NOMBRE,
        path        => $EXECUTABLE_NAME,
        user        => q{},
        pwd         => q{},
        start_type  => SERVICE_AUTO_START,
        description => 'Servicio de prueba',
        parameters  => $ruta . $NOMBRE_REAL,
    };

    if ( Win32::Daemon::CreateService($service_info) ) {
        say 'Servicio instalado correctamente';
    }
    else {
        confess 'ERROR instalando el servicio: '
            . Win32::FormatMessage( Win32::Daemon::GetLastError() );
    }
    return;
}

sub desinstalar {
    if ( Win32::Daemon::DeleteService( q{}, $NOMBRE ) ) {
        say 'Servicio desinstalado correctamente';
    }
    else {
        confess 'ERROR desinstalando el servicio: '
            . Win32::FormatMessage( Win32::Daemon::GetLastError() );
    }
    return;
}

################################################################################
#################################### PRINCIPAL #################################
################################################################################

# Si se ha pedido instalar o desinstalar
if ( defined $ARGV[0] and $ARGV[0] eq 'instalar' ) {
    instalar();
}
elsif ( defined $ARGV[0] and $ARGV[0] eq 'desinstalar' ) {
    desinstalar();
}

1;
