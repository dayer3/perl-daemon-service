#!/usr/bin/perl

use 5.022_002;
use strict;
use warnings;
use utf8;
use English qw(-no_match_vars);
use Carp;
use Log::Log4perl qw(:easy);
use Log::Log4perl::Level;
use File::Basename;
use Proc::Daemon;

my $LOG_FILE = 'log.log';
my $PAUSA    = 5;
my $log;
my $no_me_canso = 1;

################################################################################
############################### SUBRUTINAS #####################################
################################################################################

# Configuración e inicialización del log.
sub iniciar_log {
    my $opt   = shift;
    my $nivel = defined $opt ? 'DEBUG' : 'INFO';
    my $app   = basename($0);

    my $conf_logger
        = "log4perl.rootLogger = $nivel, Stdout\n"
        . "log4perl.appender.Stdout.layout = Log::Log4perl::Layout::PatternLayout\n";

    # En Linux: syslog.
    # En Windows: fichero.
    if ( $OSNAME eq 'linux' ) {
        $conf_logger
            .= "log4perl.appender.Stdout = Log::Dispatch::Syslog\n"
            . "log4perl.appender.Stdout.min_level = debug\n"
            . "log4perl.appender.Stdout.ident = $app\n"
            . "log4perl.appender.Stdout.logopt = cons,pid,ndelay\n"
            . "log4perl.appender.Stdout.layout.ConversionPattern = %p %m%n";
    }
    else {
        $conf_logger
            .= "log4perl.appender.Stdout = Log::Log4perl::Appender::File\n"
            . "log4perl.appender.Stdout.filename = $LOG_FILE\n"
            . "log4perl.appender.Stdout.utf8 = 1\n"
            . "log4perl.appender.Stdout.min_level = DEBUG\n"
            . "log4perl.appender.Stdout.layout.ConversionPattern = %d{MMM dd HH:mm:ss} %H $app\[%P\]: %p %m%n";
    }

    Log::Log4perl->init( \$conf_logger );

    return Log::Log4perl->get_logger($app);
}

sub trabajar {
    $log->info('Hago como que estoy trabajando...');
    sleep $PAUSA;
}

# Configución del demonio/servicio
sub configurar {
    if ( $OSNAME eq 'linux' ) {
        while ($no_me_canso) {
            trabajar();
        }
        $log->info('Demonio detenido.');
    }
    else {

    }
}

################################################################################
#################################### PRINCIPAL #################################
################################################################################

# Arranque.
$log = iniciar_log();
$log->info("Arrancando en $OSNAME");

# Redirección de los warnings a Log4perl, para que no se nos escapen.
$SIG{__WARN__} = sub {
    local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;
    WARN @_;
};

configurar();
