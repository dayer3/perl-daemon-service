#!/usr/bin/perl

use 5.022_002;
use strict;
use warnings;
use utf8;
use Carp;
use English qw(-no_match_vars);

use Log::Log4perl qw(:easy);
use Log::Log4perl::Level;
use File::Basename;
use Cwd 'abs_path';

# HUP, INT, PIPE, TERM
use sigtrap 'handler' => \&manejador, 'normal-signals';

my $NOMBRE = 'experimento';
my ( $NOMBRE_REAL, $RUTA ) = fileparse( abs_path($PROGRAM_NAME) );
my $LOG_FILE = $RUTA . 'log.log';
my $PAUSA    = 5;
my $log;
my $no_me_canso = 1;

################################################################################
############################### SUBRUTINAS #####################################
################################################################################

# Configuración e inicialización del log.
sub iniciar_log {
    my $opt = shift;
    my $nivel = defined $opt ? 'DEBUG' : 'INFO';

    my $conf_logger
        = "log4perl.rootLogger = $nivel, Stdout\n"
        . "log4perl.appender.Stdout.layout = Log::Log4perl::Layout::PatternLayout\n";

    # En Linux: syslog.
    # En Windows: fichero.
    if ( $OSNAME eq 'linux' ) {
        $conf_logger
            .= "log4perl.appender.Stdout = Log::Dispatch::Syslog\n"
            . "log4perl.appender.Stdout.min_level = debug\n"
            . "log4perl.appender.Stdout.ident = $NOMBRE\n"
            . "log4perl.appender.Stdout.logopt = cons,pid,ndelay\n"
            . "log4perl.appender.Stdout.layout.ConversionPattern = %p %m%n";
    }
    elsif ( $OSNAME eq 'MSWin32' ) {
        $conf_logger
            .= "log4perl.appender.Stdout = Log::Log4perl::Appender::File\n"
            . "log4perl.appender.Stdout.filename = $LOG_FILE\n"
            . "log4perl.appender.Stdout.utf8 = 1\n"
            . "log4perl.appender.Stdout.min_level = DEBUG\n"
            . "log4perl.appender.Stdout.layout.ConversionPattern = %d{MMM dd HH:mm:ss} %H $NOMBRE\[%P\]: %p %m%n";
    }

    Log::Log4perl->init( \$conf_logger );

    return Log::Log4perl->get_logger($NOMBRE);
}

sub trabajar {
    $log->info('Hago como que estoy trabajando...');

    # Detección de si el servicio (Windows) ha dejado de estar corriendo.
    if ( $OSNAME eq 'MSWin32' and not comprobar_corriendo() ) {
        $no_me_canso = 0;
    }
    if ( $no_me_canso == 0 ) {
        $log->info('Me han pedido que pare (o estoy KO)');
        return;
    }

    sleep $PAUSA;
}

# Configución del demonio/servicio
sub configurar {
    $log->info("Configurando para $OSNAME");

    if ( $OSNAME eq 'linux' ) {
        while ($no_me_canso) {
            trabajar();
        }
        $log->info('Demonio detenido.');
        exit 0;
    }
    elsif ( $OSNAME eq 'MSWin32' ) {
        require $RUTA . 'servicio.pl';
        preparar_servicio(
            {   log       => $log,
                pausa     => $PAUSA,
                daemon    => \&trabajar,
                nomecanso => \$no_me_canso,
            }
        );
        $log->info('Servicio detenido.');
        exit 0;
    }
}

# Manejador de señales
sub manejador {
    my $s = shift;

    $log->info("Recibida señal '$s'. Voy cerrando...'");
    $no_me_canso = 0;
}

################################################################################
#################################### PRINCIPAL #################################
################################################################################

# Arranque.
$log = iniciar_log();
$log->info("Arrancando en $OSNAME");

# Redirección de los warnings a Log4perl, para que no se nos escapen.
# http://log4perl.sourceforge.net/releases/Log-Log4perl/docs/html/Log/Log4perl/FAQ.html#73200
$SIG{__WARN__} = sub {
    local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;
    WARN @_;
};

configurar();
